import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
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
    expect(find.text('1 000'), findsOneWidget);
    expect(find.text('estimé'), findsWidgets);
    expect(find.text('Empoissonné'), findsOneWidget);

    await tapAndSettle(tester, find.text('E1'));
    expect(find.text('L26-01'), findsOneWidget);
    expect(find.text('Prégrossissement'), findsOneWidget);
    expect(find.textContaining('12,5 g'), findsOneWidget);
  });
}
