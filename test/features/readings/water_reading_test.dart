import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/router.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:dobo/theme/tokens.dart';
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
    await reveal(tester, find.text('O₂ 2 mg/L'));
    final o2 = tester.widget<Text>(find.text('O₂ 2 mg/L'));
    expect(o2.style?.color, DoboColors.standard.danger);
    final reading = await db.select(db.waterReadings).getSingle();
    expect(reading.oxygenMgL, 2.0);
  });

  appTest('a reading opens filled in and saves as a correction', (
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
    final id = await ReadingRepository(db, session).addWaterReading(
      WaterReadingInput(
        pondId: e1,
        at: DateTime.utc(2026, 3, 15, 5, 30),
        temperatureC: 28,
        ph: 7.2,
        oxygenMgL: 5,
        colour: WaterColour.lightGreen,
      ),
    );
    await tester.pumpAndSettle();
    appContainer(tester).read(routerProvider).push('/water/$e1?readingId=$id');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '28'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '7,2'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '5'), findsOneWidget);
    expect(find.text('15/03/2026'), findsOneWidget);
    expect(find.text('08:30'), findsOneWidget);
    await enterAndSettle(tester, field('Oxygène dissous'), '4');
    await tapAndSettle(tester, find.text('Enregistrer'));
    final current = await (db.select(
      db.waterReadings,
    )..where((r) => r.supersedesId.isNotNull())).getSingle();
    expect(current.supersedesId, id);
    expect(current.oxygenMgL, 4.0);
    expect(current.temperatureC, 28.0);
    expect(current.colour, WaterColour.lightGreen);
  });
}
