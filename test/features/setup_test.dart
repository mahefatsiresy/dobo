import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  appTest('a fresh phone opens on setup and needs a site name', (
    tester,
    db,
  ) async {
    expect(find.text('Installation'), findsOneWidget);
    await tapAndSettle(tester, find.text('Commencer'));
    expect(find.text('Obligatoire'), findsOneWidget);
    expect(await SetupRepository(db).currentSession(), isNull);
  }, setUp: false);

  appTest('setup lands on the ponds tab', (tester, db) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom du site'),
      'Ambohidratrimo',
    );
    await tapAndSettle(tester, find.text('Commencer'));
    expect(find.text('Installation'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Étangs'), findsWidgets);
    expect((await db.select(db.sites).getSingle()).name, 'Ambohidratrimo');
  }, setUp: false);
}
