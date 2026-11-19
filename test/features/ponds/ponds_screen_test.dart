import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:flutter/material.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  appTest('empty farm invites to add a pond', (tester, db) async {
    expect(find.text('Aucun étang : ajoutez le premier'), findsOneWidget);
  });

  appTest('each pond has a card; a stocked one shows estimated fish', (
    tester,
    db,
  ) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
        lengthM: 30,
        widthM: 15,
      ),
    );
    await ponds.create(
      const PondInput(
        code: 'E2',
        colour: PondColour.green,
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
    expect(find.text('E1'), findsOneWidget);
    expect(find.text('E2'), findsOneWidget);
    expect(find.text('≈\u00a01\u202f000'), findsOneWidget);
    expect(find.text('Empoissonné'), findsOneWidget);

    await tapAndSettle(tester, find.text('E1'));
    expect(find.text('L26-01'), findsOneWidget);
    expect(find.text('Prégrossissement'), findsOneWidget);
    expect(find.textContaining('12,5 g'), findsOneWidget);
  });

  appTest('a pond with a danger alert shows a red count on its card', (
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
        code: 'L1',
        pondId: e1,
        date: DateTime.now(),
        count: 1000,
        avgWeightMg: 12500,
      ),
    );
    await ReadingRepository(db, session).addWaterReading(
      WaterReadingInput(pondId: e1, at: DateTime.now().toUtc(), oxygenMgL: 2),
    );
    await tester.pumpAndSettle();
    final card = find.byType(Card);
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.error)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.warning)),
      findsNothing,
    );
  });
}
