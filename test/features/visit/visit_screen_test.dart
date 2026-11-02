import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  Future<void> farm(WidgetTester tester, AppDatabase db) async {
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
        avgWeightMg: 15000,
      ),
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Visite'));
  }

  appTest('a visit: water, conditions, summary, end', (tester, db) async {
    await farm(tester, db);
    await tapAndSettle(tester, find.text('Démarrer une visite'));
    final visit = await db.select(db.visits).getSingle();

    // Water: E1 is due; a reading from the checklist ticks it off.
    await tapAndSettle(tester, find.byKey(const ValueKey('water-E1')));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'pH'),
      '7,2',
    );
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.byKey(const ValueKey('water-E1')), findsNothing);
    expect((await db.select(db.waterReadings).getSingle()).visitId, visit.id);

    // The batch was stocked long ago: a sample is due.
    expect(find.byKey(const ValueKey('sample-L26-01-E1')), findsOneWidget);

    // Conditions: five OKs tick E1 off.
    await tapAndSettle(tester, find.byKey(const ValueKey('conditions-E1')));
    for (final key in const [
      'dike',
      'inletScreen',
      'predatorNets',
      'fence',
      'grass',
    ]) {
      await tapAndSettle(tester, find.byKey(ValueKey('ok-$key')));
    }
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.byKey(const ValueKey('conditions-E1')), findsNothing);

    await enterAndSettle(
      tester,
      find.widgetWithText(TextField, 'Résumé'),
      'Eau verte, poissons actifs',
    );
    await tapAndSettle(tester, find.text('Terminer la visite'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Terminer la visite'),
      ),
    );

    // Ending opens the draft report; the Visit tab is ready for the next.
    expect(find.text('Rapport de visite'), findsOneWidget);
    await tapAndSettle(tester, find.text('Visite'));
    expect(find.text('Démarrer une visite'), findsOneWidget);
    final ended = await db.select(db.visits).getSingle();
    expect(
      (ended.summary, ended.endedAt != null),
      ('Eau verte, poissons actifs', true),
    );
    final checks = await db.select(db.observations).get();
    expect(
      checks.where((o) => o.ok == true && o.visitId == visit.id),
      hasLength(5),
    );
  });

  appTest('an observation saves while the keyboard closes', (tester, db) async {
    await farm(tester, db);
    await tapAndSettle(tester, find.text('Démarrer une visite'));
    await tapAndSettle(tester, find.text('Ajouter une observation'));
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Digue fissurée',
    );
    await tapAsKeyboardCloses(tester, find.text('Enregistrer'));
    expect(tester.takeException(), isNull);
    expect(
      (await db.select(db.observations).getSingle()).note,
      'Digue fissurée',
    );
  });

  appTest('re-answering a condition corrects it', (tester, db) async {
    await farm(tester, db);
    await tapAndSettle(tester, find.text('Démarrer une visite'));
    await tapAndSettle(tester, find.byKey(const ValueKey('conditions-E1')));
    await tapAndSettle(tester, find.byKey(const ValueKey('ok-dike')));
    await tapAndSettle(tester, find.text('Enregistrer'));

    await tapAndSettle(tester, find.byKey(const ValueKey('conditions-E1')));
    await tapAndSettle(tester, find.text('Enregistrer')); // nothing changed
    expect(await db.select(db.observations).get(), hasLength(1));

    await tapAndSettle(tester, find.byKey(const ValueKey('conditions-E1')));
    await tapAndSettle(tester, find.byKey(const ValueKey('problem-dike')));
    await tapAndSettle(tester, find.text('Enregistrer'));
    final rows = await db.select(db.observations).get();
    expect(rows, hasLength(2));
    final fix = rows.singleWhere((o) => o.supersedesId != null);
    expect(
      (fix.ok, fix.category, fix.supersedesId),
      (
        false,
        ObservationCategory.dike,
        rows.singleWhere((o) => o.ok == true).id,
      ),
    );
  });
}
