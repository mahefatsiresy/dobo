import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> openForm(WidgetTester tester, AppDatabase db) async {
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
    await tapAndSettle(tester, find.text("Relevé d'eau"));
  }

  appTest('an empty reading is refused', (tester, db) async {
    await openForm(tester, db);
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Obligatoire'), findsOneWidget);
    expect(await db.select(db.waterReadings).get(), isEmpty);
  });

  appTest('a pH with a decimal comma is read as a decimal', (tester, db) async {
    await openForm(tester, db);
    await enterAndSettle(tester, field('pH'), '7,5');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect((await db.select(db.waterReadings).getSingle()).ph, 7.5);
  });

  appTest('low oxygen shows in red, on the form and on the pond', (
    tester,
    db,
  ) async {
    await openForm(tester, db);
    await enterAndSettle(tester, field('Oxygène dissous'), '2');
    expect(find.text('cible 3 mg/L ou plus'), findsOneWidget);
    await tapAndSettle(tester, find.text('Enregistrer'));
    final o2 = tester.widget<Text>(find.text('O₂ 2 mg/L'));
    expect(o2.style?.color, Colors.red.shade800);
    final reading = await db.select(db.waterReadings).getSingle();
    expect(reading.oxygenMgL, 2.0);
  });
}
