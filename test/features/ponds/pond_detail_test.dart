import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
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
    expect(find.text('Empoissonné'), findsNWidgets(2));
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
    await tapAndSettle(tester, find.text('Modifier'));
    await tapAndSettle(tester, find.text('Vide'));
    await tapAndSettle(tester, find.text('Prêt').last);
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect((await ponds.get(e1)).status, PondStatus.ready);
    expect(find.text('Prêt'), findsOneWidget);
  });
}
