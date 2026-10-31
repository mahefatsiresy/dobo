import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
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
      expect(await settled(tester, dangerCountProvider), 1);
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
}
