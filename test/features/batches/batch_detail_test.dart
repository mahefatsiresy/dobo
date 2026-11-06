import 'dart:io';

import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/reports/share_report.dart';
import 'package:dobo/features/sync/backup_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  appTest('a stocking corrected below what was moved out is flagged', (
    tester,
    db,
  ) async {
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
    await batches.transfer(
      TransferInput(
        batchId: l1,
        fromPondId: e1,
        toPondId: e2,
        date: DateTime(2026, 3, 10),
        count: 800,
      ),
    );
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Lots'));
    await tapAndSettle(tester, find.text('L26-01'));
    expect(find.text('Historique'), findsOneWidget);

    await tapAndSettle(tester, find.text('Corriger').last);
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, "Nombre d'alevins"),
      '500',
    );
    await tapAndSettle(tester, find.text('Enregistrer'));

    expect(tester.takeException(), isNull);
    expect(find.text('À vérifier'), findsOneWidget);
    expect(find.textContaining('800'), findsWidgets);
    final stockings = await db.select(db.stockings).get();
    expect(stockings, hasLength(2));
  });

  appTest('deleting the stocking empties the batch', (tester, db) async {
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
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Lots'));
    await tapAndSettle(tester, find.text('L26-01'));
    await tapAndSettle(tester, find.text('Supprimer'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Supprimer'),
      ),
    );
    expect(find.text('Corriger'), findsNothing);
    final rows = await db.select(db.stockings).get();
    expect(rows.where((r) => r.isTombstone), hasLength(1));
  });

  appTest('edit a batch\'s identity', (tester, db) async {
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
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Lots'));
    await tapAndSettle(tester, find.text('L26-01'));
    await tapAndSettle(tester, find.byTooltip('Modifier le lot'));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Souche (ex. GIFT)'),
      'GIFT',
    );
    await tapAndSettle(tester, find.text('Oui'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('GIFT'), findsOneWidget);
    final b = await db.select(db.batches).getSingle();
    expect((b.strain, b.monosex, b.code), ('GIFT', true, 'L26-01'));
  });

  appTest('a double tap when correcting keeps one version', (tester, db) async {
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
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Lots'));
    await tapAndSettle(tester, find.text('L26-01'));
    await tapAndSettle(tester, find.text('Corriger'));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, "Nombre d'alevins"),
      '900',
    );
    final save = find.text('Enregistrer');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final rows = await db.select(db.stockings).get();
    expect([for (final r in rows) r.count]..sort(), [900, 1000]);
  });

  appTest('Récolter and Vendre are hidden without the sales flag', (
    tester,
    db,
  ) async {
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
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Lots'));
    await tapAndSettle(tester, find.text('L26-01'));
    expect(find.text('Récolter'), findsNothing);
    expect(find.text('Vendre'), findsNothing);
  }, isSales: false);

  final shared = <File>[];
  appTest(
    'Fiche de traçabilité is shown to every member and shares a PDF',
    (tester, db) async {
      shared.clear();
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
      await tapAndSettle(tester, find.text('Plus'));
      await tapAndSettle(tester, find.text('Lots'));
      await tapAndSettle(tester, find.text('L26-01'));
      await tester.tap(find.byTooltip('Fiche de traçabilité'));
      // Database reads run on the test clock, fonts and the PDF off it.
      for (var i = 0; i < 50 && shared.isEmpty; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      }
      await tester.pumpAndSettle();
      expect(shared.single.path, endsWith('tracabilite-L26-01-2026-03-20.pdf'));
    },
    isSales: false,
    overrides: [
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 3, 20, 6)),
      reportSharerProvider.overrideWithValue((file) async => shared.add(file)),
      backupDirProvider.overrideWithValue(
        () async => Directory.systemTemp.createTemp('dobo-trace'),
      ),
    ],
  );
}
