import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/report_repository.dart';
import 'package:dobo/db/repositories/visit_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late ReportRepository reports;

  DateTime d(int day) => farmDateToUtc(DateTime(2026, 3, day));

  ReportContent content({int from = 13, int to = 20}) => ReportContent(
    header: ReportHeader(
      siteName: 'Ambohidratrimo',
      visitDay: d(to),
      memberName: 'Soa',
      periodFrom: d(from),
      periodTo: d(to),
      builtAt: DateTime.utc(2026, 3, 20, 7),
    ),
    summary: 'RAS',
  );

  setUp(() async {
    (db, session) = await setUpFarm();
    reports = ReportRepository(db, session);
  });
  tearDown(() => db.close());

  /// A report another member published, as a pull stores it.
  Future<String> pulled({
    required String visitId,
    int from = 5,
    int to = 12,
  }) async {
    final row = await db
        .into(db.visitReports)
        .insertReturning(
          VisitReportsCompanion.insert(
            associationId: session.associationId,
            enteredBy: 'someone-else',
            deviceId: 'other-phone',
            recordedAt: d(to),
            visitId: visitId,
            siteId: session.siteId,
            periodFrom: d(from),
            periodTo: d(to),
            content: content(from: from, to: to).encode(),
            syncState: const Value(SyncState.synced),
          ),
        );
    return row.id;
  }

  test('publish stores the content and the period', () async {
    final id = await reports.publish(visitId: 'v1', content: content());
    final r = await db.select(db.visitReports).getSingle();
    expect((r.id, r.visitId, r.siteId), (id, 'v1', session.siteId));
    expect((r.periodFrom, r.periodTo), (d(13), d(20)));
    expect(r.recordedAt, DateTime.utc(2026, 3, 20, 7));
    expect(ReportContent.decode(r.content).summary, 'RAS');
  });

  test('publish twice for one visit throws and writes one row', () async {
    await reports.publish(visitId: 'v1', content: content());
    await expectLater(
      reports.publish(visitId: 'v1', content: content()),
      throwsA(isA<ReportAlreadyPublished>()),
    );
    expect(await db.select(db.visitReports).get(), hasLength(1));
  });

  test(
    'a pulled report from another member is unread until markRead',
    () async {
      final id = await pulled(visitId: 'v0');
      expect(await reports.watchUnreadIds().first, {id});
      await reports.markRead(id);
      expect(await reports.watchUnreadIds().first, isEmpty);
    },
  );

  test('my own published report is never unread', () async {
    await reports.publish(visitId: 'v1', content: content());
    expect(await reports.watchUnreadIds().first, isEmpty);
  });

  test('reports are listed newest period first', () async {
    final older = await pulled(visitId: 'v0', from: 1, to: 5);
    final newer = await reports.publish(visitId: 'v1', content: content());
    final mid = await pulled(visitId: 'v2', from: 5, to: 12);
    expect(
      [for (final r in await reports.watchAll().first) r.id],
      [newer, mid, older],
    );
  });

  test('previousPeriodTo ignores this visit and later reports', () async {
    await pulled(visitId: 'v0', from: 1, to: 12);
    await pulled(visitId: 'v-later', from: 20, to: 25);
    await pulled(visitId: 'v1', from: 12, to: 20);
    expect(
      await reports
          .watchPreviousPeriodTo(visitDay: d(20), excludingVisitId: 'v1')
          .first,
      d(12),
    );
    expect(
      await reports
          .watchPreviousPeriodTo(visitDay: d(10), excludingVisitId: 'v9')
          .first,
      isNull,
    );
  });

  test('watchForVisit finds the current report', () async {
    expect(await reports.watchForVisit('v1').first, isNull);
    final id = await reports.publish(visitId: 'v1', content: content());
    expect((await reports.watchForVisit('v1').first)?.id, id);
  });

  test('the latest ended visit is mine and ended', () async {
    final visits = VisitRepository(db, session);
    expect(await visits.watchLatestEndedByMe().first, isNull);
    final a = await visits.start();
    await visits.end(a);
    final b = await visits.start();
    expect((await visits.watchLatestEndedByMe().first)?.id, a);
    await visits.end(b);
    expect((await visits.watchLatestEndedByMe().first)?.id, b);
  });
}
