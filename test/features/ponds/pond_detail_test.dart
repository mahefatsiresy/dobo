import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/readings/water_reading_screen.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/mini_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  appTest('a pond with fish is not archived', (tester, db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final e1 = await PondRepository(db, session).create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    await BatchRepository(db, session).stockBatch(
      StockInput(
        code: 'L26-01',
        pondId: e1,
        date: DateTime(2026, 3, 1),
        count: 1000,
        avgWeightMg: 12500,
      ),
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.byTooltip("Plus d'actions"));
    await tapAndSettle(tester, find.text('Archiver'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Archiver'),
      ),
    );
    expect(find.textContaining('contient encore des poissons'), findsOneWidget);
    expect((await db.select(db.ponds).getSingle()).archived, isFalse);
  });

  appTest('a pond shows the status its fish give', (tester, db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final batches = BatchRepository(db, session);
    final e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    final e2 = await ponds.create(
      const PondInput(
        code: 'E2',
        colour: PondColour.green,
        role: PondRole.growout,
      ),
    );
    final l1 = await batches.stockBatch(
      StockInput(
        code: 'L26-01',
        pondId: e1,
        date: DateTime(2026, 3, 1),
        count: 1000,
        avgWeightMg: 12500,
      ),
    );
    // A correction leaves 100 fish in E1 after all 1 000 moved to E2.
    final st = (await db.select(db.stockings).getSingle()).id;
    await batches.transfer(
      TransferInput(
        batchId: l1,
        fromPondId: e1,
        toPondId: e2,
        date: DateTime(2026, 3, 10),
        count: 1000,
      ),
    );
    await batches.correctStocking(
      st,
      StockingCorrection(
        pondId: e1,
        date: DateTime(2026, 3, 1),
        count: 1100,
        avgWeightMg: 12500,
      ),
    );
    await tester.pumpAndSettle();
    // Both hold fish: stocked rows with their count, neither empty.
    expect(find.text('≈\u00a0100 poissons'), findsOneWidget);
    expect(find.text('≈\u00a01\u202f000 poissons'), findsOneWidget);
    expect(find.text('Vide'), findsNothing);
  });

  appTest('an emptied pond can be marked ready by hand', (tester, db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    await ponds.setStatus(e1, PondStatus.stocked); // no fish: shows empty
    await tester.pumpAndSettle();
    expect(find.text('Vide'), findsOneWidget);
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.byTooltip("Plus d'actions"));
    await tapAndSettle(tester, find.text('Modifier'));
    await tapAndSettle(tester, find.text('Plus de détails'));
    await tapAndSettle(tester, find.text('Prêt'));
    await tapAndSettle(tester, find.text("Enregistrer l'étang"));
    expect((await ponds.get(e1)).status, PondStatus.ready);
    await tapAndSettle(tester, find.text('Étangs'));
    expect(find.text('Prêt'), findsOneWidget); // E1's card
  });

  group('dashboard', () {
    final now = DateTime.utc(2026, 3, 20, 6); // 09:00 in Madagascar
    final clock = clockProvider.overrideWithValue(() => now);

    /// E1 (500 m²) with L1 (1 000 fish at 10 g on 01/03), weighed at 20 g
    /// on 08/03 and 30 g on 15/03, fed 15 kg then 16 kg: FCR 1.5 then 1.6.
    Future<String> weighedPond(AppDatabase db, {bool shared = false}) async {
      final session = (await SetupRepository(db).currentSession())!;
      final e1 = await PondRepository(db, session).create(
        const PondInput(
          code: 'E1',
          colour: PondColour.blue,
          role: PondRole.growout,
          lengthM: 25,
          widthM: 20,
        ),
      );
      final batches = BatchRepository(db, session);
      final l1 = await batches.stockBatch(
        StockInput(
          code: 'L1',
          pondId: e1,
          date: DateTime(2026, 3, 1),
          count: 1000,
          avgWeightMg: 10000,
        ),
      );
      if (shared) {
        await batches.transfer(
          TransferInput(
            batchId: await batches.stockBatch(
              StockInput(
                code: 'L2',
                pondId: await PondRepository(db, session).create(
                  const PondInput(
                    code: 'E2',
                    colour: PondColour.green,
                    role: PondRole.growout,
                  ),
                ),
                date: DateTime(2026, 3, 1),
                count: 100,
                avgWeightMg: 10000,
              ),
            ),
            fromPondId: (await db.select(db.ponds).get())
                .singleWhere((p) => p.code == 'E2')
                .id,
            toPondId: e1,
            date: DateTime(2026, 3, 10),
            count: 50,
          ),
        );
      }
      final logs = DailyLogRepository(db, session);
      await logs.save(
        DailyLogInput(
          pondId: e1,
          date: DateTime(2026, 3, 5),
          feedGivenG: 15000,
        ),
      );
      await logs.save(
        DailyLogInput(
          pondId: e1,
          date: DateTime(2026, 3, 12),
          feedGivenG: 16000,
        ),
      );
      final readings = ReadingRepository(db, session);
      for (final (day, grams) in [(8, 800), (15, 1200)]) {
        await readings.addSample(
          SampleInput(
            batchId: l1,
            pondId: e1,
            date: DateTime(2026, 3, day),
            fishCount: 40,
            totalWeightG: grams,
          ),
        );
      }
      return e1;
    }

    appTest('pond page shows ration, FCR with arrow, survival', (
      tester,
      db,
    ) async {
      await weighedPond(db);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('E1'));
      // 1 000 × 30 g × 4 % = 1,2 kg.
      expect(find.text('Ration du jour'), findsOneWidget);
      expect(find.text('≈\u00a01,2 kg'), findsWidgets);
      expect(find.text('IC : 1,6 ↑'), findsOneWidget);
      expect(find.text('Survie : 100 %'), findsOneWidget);
      expect(find.text('Dernière pesée : il y a 5 j'), findsOneWidget);
    }, overrides: [clock]);

    appTest('pond page lists its alerts and tapping one navigates', (
      tester,
      db,
    ) async {
      await weighedPond(db);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('E1'));
      await tapAndSettle(tester, find.text("Relevé d'eau à faire"));
      expect(find.byType(WaterReadingScreen), findsOneWidget);
    }, overrides: [clock]);

    appTest('shared pond shows IC —', (tester, db) async {
      await weighedPond(db, shared: true);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('E1'));
      expect(find.text('IC : —'), findsOneWidget);
    }, overrides: [clock]);

    appTest('three charts open one by one, no overflow on a 360 × 640 phone', (
      tester,
      db,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      await weighedPond(db);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('E1'));
      expect(find.byType(MiniChart), findsNothing); // folded
      var opened = 0;
      for (final title in [
        'Poids moyen (g)',
        'Morts par jour',
        'IC par période',
      ]) {
        await tapAndSettle(tester, find.text(title));
        opened++;
        expect(
          find.byType(MiniChart, skipOffstage: false),
          findsNWidgets(opened),
        );
        expect(tester.takeException(), isNull);
        // The chart keeps its name for screen readers.
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(title))),
          findsWidgets,
        );
      }
      handle.dispose();
    }, overrides: [clock]);
  });
}
