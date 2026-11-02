import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/report_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/repositories/visit_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/reports/report_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';

void main() {
  final now = DateTime.utc(2026, 3, 20, 6); // 09:00 in Madagascar
  DateTime d(int day) => farmDateToUtc(DateTime(2026, 3, day));

  Future<T> settled<T>(
    WidgetTester tester,
    ProviderListenable<T> provider,
  ) async {
    final sub = appContainer(tester).listen(provider, (_, _) {});
    await tester.pumpAndSettle();
    final value = sub.read();
    sub.close();
    return value;
  }

  Future<Session> session(AppDatabase db) async =>
      (await SetupRepository(db).currentSession())!;

  /// A report another member published, as a pull stores it.
  Future<String> pulled(
    AppDatabase db, {
    required String visitId,
    required int to,
    List<PondHealth> health = const [],
  }) async {
    final s = await session(db);
    final content = ReportContent(
      header: ReportHeader(
        siteName: 'Ambohidratrimo',
        visitDay: d(to),
        memberName: 'Hery',
        periodFrom: d(to - 7),
        periodTo: d(to),
        builtAt: d(to),
      ),
      health: health,
    );
    final row = await db
        .into(db.visitReports)
        .insertReturning(
          VisitReportsCompanion.insert(
            associationId: s.associationId,
            enteredBy: 'someone-else',
            deviceId: 'other-phone',
            recordedAt: d(to),
            visitId: visitId,
            siteId: s.siteId,
            periodFrom: d(to - 7),
            periodTo: d(to),
            content: content.encode(),
            syncState: const Value(SyncState.synced),
          ),
        );
    return row.id;
  }

  appTest('a pulled report shows its author\'s numbers and is unread', (
    tester,
    db,
  ) async {
    final id = await pulled(
      db,
      visitId: 'v0',
      to: 12,
      health: const [PondHealth(pondId: 'e9', deaths: 7)],
    );
    expect(await settled(tester, unreadCountProvider), 1);
    final content = (await settled(
      tester,
      reportContentProvider(id),
    )).requireValue!;
    // This phone has no logs at all; the report keeps the author's count.
    expect(content.health.single.deaths, 7);
  }, overrides: [clockProvider.overrideWithValue(() => now)]);

  appTest('content from a newer app reads as null', (tester, db) async {
    final id = await pulled(db, visitId: 'v0', to: 12);
    await (db.update(db.visitReports)..where((r) => r.id.equals(id))).write(
      const VisitReportsCompanion(content: Value('{"format":2}')),
    );
    expect(
      (await settled(tester, reportContentProvider(id))).requireValue,
      isNull,
    );
  });

  appTest('the draft is my latest ended visit, until it is published', (
    tester,
    db,
  ) async {
    final s = await session(db);
    final visits = VisitRepository(db, s);
    final a = await visits.start();
    await visits.end(a);
    final b = await visits.start();
    await visits.end(b);
    expect((await settled(tester, draftVisitProvider))?.id, b);

    await ReportRepository(db, s).publish(
      visitId: b,
      content: (await settled(tester, draftReportProvider(b))).requireValue,
    );
    // The older unreported visit is never offered.
    expect(await settled(tester, draftVisitProvider), isNull);
  }, overrides: [clockProvider.overrideWithValue(() => now)]);

  appTest('the draft starts on the previous report\'s last day', (
    tester,
    db,
  ) async {
    final s = await session(db);
    await pulled(db, visitId: 'v0', to: 15);
    final visits = VisitRepository(db, s);
    final v = await visits.start();
    await visits.setSummary(v, 'Digue à reprendre');
    await visits.end(v);
    final content = (await settled(
      tester,
      draftReportProvider(v),
    )).requireValue;
    expect(content.header.periodFrom, d(15));
    expect(content.header.periodTo, farmDateToUtc(farmDate(DateTime.now())));
    expect(content.summary, 'Digue à reprendre');
    expect(content.header.siteName, 'Ambohidratrimo');
  });

  appTest('the draft counts the period\'s deaths and lists the pond', (
    tester,
    db,
  ) async {
    final s = await session(db);
    final e1 = await PondRepository(db, s).create(pondInput('E1'));
    await BatchRepository(db, s).stockBatch(
      stockInput(
        'L1',
        pondId: e1,
        date: DateTime.now().subtract(const Duration(days: 10)),
      ),
    );
    await DailyLogRepository(db, s).save(
      DailyLogInput(
        pondId: e1,
        date: DateTime.now().subtract(const Duration(days: 1)),
        feedGivenG: 2000,
        deaths: 4,
      ),
    );
    final visits = VisitRepository(db, s);
    final v = await visits.start();
    await visits.end(v);
    final content = (await settled(
      tester,
      draftReportProvider(v),
    )).requireValue;
    expect(content.health.single.deaths, 4);
    expect(content.pondCodes[e1], 'E1');
    expect(content.feedTotalG, 2000);
    expect(content.growth.single.pondId, e1);
  });
}
