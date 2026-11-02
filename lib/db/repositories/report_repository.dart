import 'package:drift/drift.dart';

import '../../domain/report/report_content.dart';
import '../database.dart';
import '../events.dart';
import '../ids.dart';
import '../session.dart';

/// The visit already has a published report (plan Decision 2).
class ReportAlreadyPublished implements Exception {}

/// Published visit reports (SPEC F8) and this phone's read marks.
class ReportRepository {
  ReportRepository(this.db, this.session);

  final AppDatabase db;
  final Session session;

  /// Publishes [content] as [visitId]'s report; returns its id. Throws
  /// [ReportAlreadyPublished] when the visit has one.
  Future<String> publish({
    required String visitId,
    required ReportContent content,
  }) => db.transaction(() async {
    if (await _forVisit(visitId).getSingleOrNull() != null) {
      throw ReportAlreadyPublished();
    }
    final row = await db
        .into(db.visitReports)
        .insertReturning(
          VisitReportsCompanion.insert(
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            recordedAt: content.header.builtAt,
            visitId: visitId,
            siteId: session.siteId,
            periodFrom: content.header.periodFrom,
            periodTo: content.header.periodTo,
            content: content.encode(),
          ),
        );
    await markRead(row.id);
    return row.id;
  });

  /// The site's current reports, newest period first.
  Stream<List<VisitReport>> watchAll() =>
      (db.select(db.visitReports)
            ..where(
              (r) =>
                  isCurrentEvent(db.visitReports) &
                  r.siteId.equals(session.siteId),
            )
            ..orderBy([
              (r) => OrderingTerm.desc(r.periodTo),
              (r) => OrderingTerm.desc(r.recordedAt),
            ]))
          .watch();

  Stream<VisitReport?> watchForVisit(String visitId) =>
      _forVisit(visitId).watchSingleOrNull();

  /// The last day of the latest report before [visitDay] (that day
  /// included), other than [excludingVisitId]'s: where the next period
  /// starts (plan Decision 3).
  Stream<DateTime?> watchPreviousPeriodTo({
    required DateTime visitDay,
    required String excludingVisitId,
  }) {
    final latest = db.visitReports.periodTo.max();
    final q = db.selectOnly(db.visitReports)
      ..addColumns([latest])
      ..where(
        isCurrentEvent(db.visitReports) &
            db.visitReports.siteId.equals(session.siteId) &
            db.visitReports.visitId.equals(excludingVisitId).not() &
            db.visitReports.periodTo.isSmallerOrEqualValue(visitDay),
      );
    return q.map((r) => r.read(latest)).watchSingle();
  }

  Future<void> markRead(String reportId) => db
      .into(db.reportReads)
      .insert(
        ReportReadsCompanion.insert(reportId: reportId, readAt: utcNow()),
        mode: InsertMode.insertOrIgnore,
      );

  /// Current reports someone else published that this phone hasn't opened.
  Stream<Set<String>> watchUnreadIds() {
    final read = db.reportReads;
    final q =
        db.select(db.visitReports).join([
          leftOuterJoin(read, read.reportId.equalsExp(db.visitReports.id)),
        ])..where(
          isCurrentEvent(db.visitReports) &
              db.visitReports.enteredBy.equals(session.userId).not() &
              read.reportId.isNull(),
        );
    return q.watch().map(
      (rows) => {for (final r in rows) r.readTable(db.visitReports).id},
    );
  }

  SimpleSelectStatement<$VisitReportsTable, VisitReport> _forVisit(
    String visitId,
  ) => db.select(db.visitReports)
    ..where((r) => isCurrentEvent(db.visitReports) & r.visitId.equals(visitId))
    ..limit(1);
}
