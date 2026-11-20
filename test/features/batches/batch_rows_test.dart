import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/health_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/features/batches/batch_rows.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/ponds/pond_attention.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

/// The rows once loaded, on the demo farm with its trade.
Future<List<BatchRow>> _rows(
  WidgetTester tester,
  AppDatabase db, {
  Future<void> Function(DemoFarm farm)? before,
}) async {
  final farm = await seedDemoFarm(db);
  await seedDemoTrade(db, farm);
  await before?.call(farm);
  await tester.pumpAndSettle();
  final container = appContainer(tester);
  final sub = container.listen(batchRowsProvider, (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 50 && !sub.read().hasValue; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return sub.read().requireValue;
}

BatchRow _row(List<BatchRow> rows, String code) =>
    rows.singleWhere((r) => r.batch.code == code);

void main() {
  appTest('a batch in two ponds: both places, no single weight or phase', (
    tester,
    db,
  ) async {
    final rows = await _rows(tester, db);
    final l1 = _row(rows, 'L-E1');
    expect(l1.places.map((p) => p.pond.code), ['E1', 'P2']);
    expect(l1.avgWeightG, isNull);
    expect(l1.phase, isNull);
    expect(l1.biomassG, l1.places.fold<int>(0, (n, p) => n + p.biomassG!));
    expect(
      l1.liveCount,
      l1.places.fold<int>(0, (n, p) => n + p.placement.live.count),
    );
  }, overrides: [_clock]);

  appTest('a batch in one pond has its weight and phase', (tester, db) async {
    final rows = await _rows(tester, db);
    final l3 = _row(rows, 'L-E3');
    expect(l3.avgWeightG, l3.places.single.placement.avgWeightG);
    expect(l3.avgWeightG, isNotNull);
    expect(l3.phase, isNotNull);
  }, overrides: [_clock]);

  appTest('only open batches, in code order', (tester, db) async {
    final rows = await _rows(tester, db);
    expect(rows.map((r) => r.batch.code), [
      'L-E1',
      'L-E2',
      'L-E3',
      'L-E4',
      'L-E5',
      'L-E6',
    ]);
  }, overrides: [_clock]);

  appTest('isolation and a count to check lead the batch band', (
    tester,
    db,
  ) async {
    final rows = await _rows(tester, db);
    expect(_row(rows, 'L-E4').attention!.lead, isA<LeadIsolated>());
    expect(_row(rows, 'L-E5').attention!.lead, isA<LeadInconsistent>());
    expect(_row(rows, 'L-E3').attention!.severity, BandSeverity.warning);
  }, overrides: [_clock]);

  appTest('isolated first, then the rest counted', (tester, db) async {
    final rows = await _rows(
      tester,
      db,
      before: (farm) async {
        // L-E1 now also sits in an isolated pond, P2.
        final session = (await SetupRepository(db).currentSession())!;
        await HealthRepository(db, session).report(
          pondId: farm['P2']!,
          signs: const {},
          isolate: true,
          technicianCalled: false,
        );
      },
    );
    final a = _row(rows, 'L-E1').attention!;
    expect(a.lead, isA<LeadIsolated>());
    expect(_row(rows, 'L-E1').items.first.pond?.code, 'P2');
  }, overrides: [_clock]);

  appTest('closed batches with the day they closed', (tester, db) async {
    await _rows(tester, db);
    final container = appContainer(tester);
    final sub = container.listen(closedBatchesProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 50 && !sub.read().hasValue; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final closed = sub.read().requireValue;
    expect(closed.map((c) => c.batch.code), ['L-E7']);
    expect(closed.single.closedOn, DateTime(2026, 2, 2));
  }, overrides: [_clock]);
}
