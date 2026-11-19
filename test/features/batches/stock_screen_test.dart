import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  appTest('stock a ready pond from its page', (tester, db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
        lengthM: 25,
        widthM: 20,
      ),
    );
    await ponds.setStatus(e1, PondStatus.ready);
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Empoissonner'));
    expect(find.text('L26-01'), findsOneWidget);
    expect(find.textContaining('Faire flotter le sac fermé'), findsOneWidget);
    await enterAndSettle(tester, field("Nombre d'alevins"), '1500');
    await enterAndSettle(tester, field('Poids moyen'), '15');
    expect(find.textContaining('3,0 /m²'), findsOneWidget);
    expect(find.textContaining('Densité'), findsWidgets);
    expect(find.textContaining('au-dessus'), findsNothing);

    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('L26-01'), findsWidgets);
    expect(find.textContaining('1 500'), findsWidgets);
    expect(find.textContaining('15 g'), findsWidgets);
    expect((await ponds.get(e1)).status, PondStatus.stocked);
  });

  appTest('count and weight are required', (tester, db) async {
    final session = (await SetupRepository(db).currentSession())!;
    await PondRepository(db, session).create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Empoissonner'));
    expect(
      find.textContaining("L'étang n'est pas marqué prêt"),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Obligatoire'), findsWidgets);
    expect(await db.select(db.batches).get(), isEmpty);
  });

  appTest('back leaves the stock screen', (tester, db) async {
    final session = (await SetupRepository(db).currentSession())!;
    await PondRepository(db, session).create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Empoissonner'));
    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.text('Empoissonner'), findsOneWidget);
    expect(find.byTooltip("Plus d'actions"), findsOneWidget); // the pond page
  });
}
