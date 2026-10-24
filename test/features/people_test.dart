import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  appTest('add a person, then mark them inactive', (tester, db) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Personnes'));
    await tapAndSettle(tester, find.text('Ajouter'));
    await tester.enterText(field('Nom'), 'Rakoto');
    await tester.enterText(field('Téléphone'), '034 00 000 00');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Rakoto'), findsOneWidget);

    await tapAndSettle(tester, find.text('Ajouter'));
    await tester.enterText(field('Nom'), 'Soa');
    await tapAndSettle(tester, find.text('Enregistrer'));

    await tapAndSettle(tester, find.text('Rakoto'));
    await tapAndSettle(tester, find.text('Actif'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    final rows = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => ((t.title! as Text).data, t.enabled))
        .toList();
    expect(rows, [('Soa', true), ('Rakoto', true)]);
    expect(find.text('Inactif'), findsOneWidget);
    final rakoto = (await db.select(db.people).get()).singleWhere(
      (p) => p.name == 'Rakoto',
    );
    expect((rakoto.active, rakoto.phone), (false, '034 00 000 00'));
  });

  appTest('a person needs a name', (tester, db) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Personnes'));
    await tapAndSettle(tester, find.text('Ajouter'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Obligatoire'), findsOneWidget);
    expect(await db.select(db.people).get(), isEmpty);
  });
}
