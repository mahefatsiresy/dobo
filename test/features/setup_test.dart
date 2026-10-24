import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('a fresh phone opens on setup and needs a site name',
      (tester) async {
    final db = testDatabase();
    await pumpApp(tester, db);
    expect(find.text('Installation'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Obligatoire'), findsOneWidget);
    expect(await SetupRepository(db).currentSession(), isNull);
  });

  testWidgets('setup lands on the ponds tab', (tester) async {
    final db = testDatabase();
    await pumpApp(tester, db);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du site'), 'Ambohidratrimo');
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Installation'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Étangs'), findsWidgets);
    expect((await db.select(db.sites).getSingle()).name, 'Ambohidratrimo');
  });
}
