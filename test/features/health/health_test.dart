import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  Future<void> stockedPond(WidgetTester tester, AppDatabase db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
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
        avgWeightMg: 15000,
      ),
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
  }

  Future<void> isolate(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Signaler un problème'));
    await tapAndSettle(tester, find.text('Se frotte'));
    await tapAndSettle(tester, find.text("Isoler l'étang"));
    await tapAndSettle(tester, find.text('Enregistrer'));
  }

  appTest('isolating shows everywhere and stops fish leaving', (
    tester,
    db,
  ) async {
    await stockedPond(tester, db);
    expect(find.text('Information, pas un diagnostic'), findsNothing);
    await tapAndSettle(tester, find.text('Signaler un problème'));
    expect(find.text('Information, pas un diagnostic'), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton));
    await isolate(tester);

    // The band heads the pond page, above where the form left it.
    await reveal(tester, find.text('Étang isolé'));
    expect(find.text('Étang isolé'), findsWidgets);
    await tapAndSettle(tester, find.text('Transférer'));
    expect(
      find.text('Étang isolé : aucun poisson ne doit en sortir'),
      findsOneWidget,
    );
    expect(find.text('Enregistrer'), findsNothing);
    await tapAndSettle(tester, find.byType(BackButton));
    await tapAndSettle(tester, find.text('Étangs'));
    // E1's band only.
    expect(find.textContaining('Étang isolé'), findsOneWidget);
    final event = await db.select(db.healthEvents).getSingle();
    expect(event.signs, {WarningSign.rubbing});
  });

  appTest('releasing lifts the banner', (tester, db) async {
    await stockedPond(tester, db);
    await isolate(tester);
    await tapAndSettle(tester, find.text("Lever l'isolement"));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text("Lever l'isolement"),
      ),
    );
    expect(find.text('Étang isolé'), findsNothing);
    await tapAndSettle(tester, find.text('Étangs'));
    expect(find.textContaining('Étang isolé'), findsNothing); // no band
  });

  appTest('a treatment is recorded and never suggested', (tester, db) async {
    await stockedPond(tester, db);
    await tapAndSettle(tester, find.text('Traitement'));
    final product = find.widgetWithText(TextFormField, 'Produit');
    expect(tester.widget<TextFormField>(product).controller!.text, isEmpty);
    expect(find.byType(Autocomplete<String>), findsNothing);
    await enterAndSettle(tester, product, 'Sel');
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Dose'),
      '3 kg',
    );
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Conseillé par'),
      'Dr Rabe',
    );
    await tapAndSettle(tester, find.text('Enregistrer'));
    // The health history is folded to one line; open it.
    await tapAndSettle(tester, find.text('Santé'));
    expect(find.textContaining('Sel'), findsOneWidget);
    final t = await db.select(db.treatments).getSingle();
    expect((t.product, t.dose, t.advisedBy), ('Sel', '3 kg', 'Dr Rabe'));
  });

  appTest('a treatment needs a product and a dose', (tester, db) async {
    await stockedPond(tester, db);
    await tapAndSettle(tester, find.text('Traitement'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Obligatoire'), findsNWidgets(2));
    expect(await db.select(db.treatments).get(), isEmpty);
  });
}
