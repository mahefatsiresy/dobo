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

  appTest('a stocked pond\'s status can be fixed by hand', (tester, db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    await ponds.setStatus(e1, PondStatus.stocked);
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Modifier'));
    await tapAndSettle(tester, find.text('Empoissonné'));
    await tapAndSettle(tester, find.text('Vide').last);
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect((await ponds.get(e1)).status, PondStatus.empty);
  });
}
