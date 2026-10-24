import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  appTest('a small square pond shows its surface and soft warnings', (
    tester,
    db,
  ) async {
    await tapAndSettle(tester, find.text('Ajouter un étang'));
    await enterAndSettle(tester, field('Code'), 'E1');
    await enterAndSettle(tester, field('Longueur'), '10');
    await enterAndSettle(tester, field('Largeur'), '10');
    await tester.pumpAndSettle();
    expect(find.textContaining('100 m²'), findsWidgets);
    expect(find.textContaining('Surface sous 200 m²'), findsOneWidget);
    expect(find.textContaining('Étang peu allongé'), findsOneWidget);
    await tapAndSettle(tester, find.text('Enregistrer'));
    final pond = await db.select(db.ponds).getSingle();
    expect(
      (pond.code, pond.lengthM, pond.widthM, pond.colour),
      ('E1', 10.0, 10.0, PondColour.blue),
    );
    expect(find.text('E1'), findsOneWidget);
  });

  appTest('a decimal comma is read as a decimal', (tester, db) async {
    await tapAndSettle(tester, find.text('Ajouter un étang'));
    await enterAndSettle(tester, field('Code'), 'E1');
    await enterAndSettle(tester, field('Longueur'), '30,5');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect((await db.select(db.ponds).getSingle()).lengthM, 30.5);
  });

  appTest('a code already used is refused', (tester, db) async {
    await tapAndSettle(tester, find.text('Ajouter un étang'));
    await enterAndSettle(tester, field('Code'), 'E1');
    await tapAndSettle(tester, find.text('Enregistrer'));
    await tapAndSettle(tester, find.text('Ajouter un étang'));
    await enterAndSettle(tester, field('Code'), 'e1');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Ce code existe déjà'), findsOneWidget);
    expect(await db.select(db.ponds).get(), hasLength(1));
  });

  appTest('the second pond gets the next colour', (tester, db) async {
    await tapAndSettle(tester, find.text('Ajouter un étang'));
    await enterAndSettle(tester, field('Code'), 'E1');
    await tapAndSettle(tester, find.text('Enregistrer'));
    await tapAndSettle(tester, find.text('Ajouter un étang'));
    await enterAndSettle(tester, field('Code'), 'E2');
    await tapAndSettle(tester, find.text('Enregistrer'));
    final colours = {
      for (final p in await db.select(db.ponds).get()) p.code: p.colour,
    };
    expect(colours, {'E1': PondColour.blue, 'E2': PondColour.green});
  });
}
