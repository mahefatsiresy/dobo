import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/feed_repository.dart';
import 'package:dobo/db/repositories/prep_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/alerts/worker_advice.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/alerts/alert_providers.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';

void main() {
  final now = DateTime.utc(2026, 3, 20, 6); // 09:00 in Madagascar

  Future<(String, String, ReadingRepository)> farm(
    AppDatabase db, {
    required DateTime stockedOn,
  }) async {
    final session = (await SetupRepository(db).currentSession())!;
    final e1 = await PondRepository(
      db,
      session,
    ).create(pondInput('E1', lengthM: 25, widthM: 20));
    final l1 = await BatchRepository(
      db,
      session,
    ).stockBatch(stockInput('L1', pondId: e1, date: stockedOn));
    return (e1, l1, ReadingRepository(db, session));
  }

  /// Keeps [provider] listened to while the app settles, then reads it.
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

  appTest(
    'a reading with 2 mg/L oxygen makes a danger alert and dangerCount 1',
    (tester, db) async {
      final (e1, _, readings) = await farm(
        db,
        stockedOn: DateTime(2026, 3, 12),
      );
      await readings.addWaterReading(
        WaterReadingInput(pondId: e1, at: now, oxygenMgL: 2),
      );
      final alerts = (await settled(tester, alertsProvider)).requireValue;
      final water = alerts.singleWhere(
        (a) => a.kind == AlertKind.waterOutOfRange,
      );
      expect((water.pondId, water.severity), (e1, Severity.danger));
      expect(await settled(tester, dangerPondsProvider), (
        ponds: 1,
        farmWide: 0,
      ));
      expect(await settled(tester, pondAlertsProvider(e1)), contains(water));
      expect(await settled(tester, stopFeedingProvider(e1)), {
        StopFeedingReason.lowOxygen,
      });
    },
    overrides: [clockProvider.overrideWithValue(() => now)],
  );

  appTest('alerts update after a sample is saved', (tester, db) async {
    final (e1, l1, readings) = await farm(db, stockedOn: DateTime(2026, 3, 1));
    bool due(List<Alert> all) => all.any((a) => a.kind == AlertKind.sampleDue);
    expect(due((await settled(tester, alertsProvider)).requireValue), isTrue);
    await readings.addSample(
      SampleInput(
        batchId: l1,
        pondId: e1,
        date: DateTime(2026, 3, 19),
        fishCount: 40,
        totalWeightG: 800,
      ),
    );
    expect(due((await settled(tester, alertsProvider)).requireValue), isFalse);
  }, overrides: [clockProvider.overrideWithValue(() => now)]);

  group('pre-harvest fast', () {
    // Harvest planned 22/03: the fast opens 20/03 at 06:00 farm time.
    var clock = DateTime.utc(2026, 3, 20, 2); // 05:00 in Madagascar
    appTest('opens at 06:00 with no record saved, closes at the harvest', (
      tester,
      db,
    ) async {
      final session = (await SetupRepository(db).currentSession())!;
      final e1 = await PondRepository(db, session).create(pondInput('E1'));
      await BatchRepository(db, session).stockBatch(
        StockInput(
          code: 'L1',
          pondId: e1,
          date: DateTime(2026, 3, 10),
          count: 1000,
          avgWeightMg: 10000,
          plannedHarvestOn: DateTime(2026, 3, 22),
        ),
      );
      bool fasting(List<Alert> all) =>
          all.any((a) => a.kind == AlertKind.preHarvestFast);
      final sub = appContainer(tester).listen(alertsProvider, (_, _) {});
      await tester.pumpAndSettle();
      expect(fasting(sub.read().requireValue), isFalse);

      clock = DateTime.utc(2026, 3, 20, 3, 1); // 06:01
      await tester.pump(const Duration(minutes: 61));
      await tester.pumpAndSettle();
      expect(fasting(sub.read().requireValue), isTrue);

      clock = DateTime.utc(2026, 3, 22, 3, 1); // 06:01 on harvest day
      await tester.pump(const Duration(hours: 48));
      await tester.pumpAndSettle();
      expect(fasting(sub.read().requireValue), isFalse);
      sub.close();
    }, overrides: [clockProvider.overrideWithValue(() => clock)]);
  });

  appTest('an old feed lot and a drained pond reach the alerts', (
    tester,
    db,
  ) async {
    final session = (await SetupRepository(db).currentSession())!;
    final e2 = await PondRepository(db, session).create(pondInput('E2'));
    await PrepRepository(
      db,
      session,
    ).record(e2, PrepStep.drain, on: DateTime(2026, 3, 14));
    await FeedRepository(db, session).deliver(
      FeedDeliveryInput(
        date: DateTime(2026, 3, 1),
        phase: Phase.growout,
        weightG: 25000,
        manufacturedOn: DateTime(2026, 1, 10),
      ),
    );
    final alerts = (await settled(tester, alertsProvider)).requireValue;
    final kinds = {for (final a in alerts) a.kind: a};
    expect(kinds[AlertKind.feedTooOld]!.severity, Severity.warning);
    expect(kinds[AlertKind.prepStepDue]!.pondId, e2);
  }, overrides: [clockProvider.overrideWithValue(() => now)]);
}
