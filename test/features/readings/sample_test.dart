import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/router.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> openForm(WidgetTester tester, AppDatabase db) async {
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
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Peser'));
  }

  appTest('a sample needs fish and a weight', (tester, db) async {
    await openForm(tester, db);
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Obligatoire'), findsNWidgets(2));
    await enterAndSettle(tester, field('Poissons pesés'), '0');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(await db.select(db.samples).get(), isEmpty);
  });

  appTest('a small sample warns and sets the weight', (tester, db) async {
    await openForm(tester, db);
    await enterAndSettle(tester, field('Poissons pesés'), '20');
    await enterAndSettle(tester, field('Poids total'), '0,62');
    expect(find.text('Poids moyen : 31 g'), findsOneWidget);
    expect(find.textContaining('Petit échantillon'), findsOneWidget);
    await tapAndSettle(tester, find.text('Enregistrer'));
    final s = await db.select(db.samples).getSingle();
    expect((s.fishCount, s.totalWeightG), (20, 620));
    // The pond page's batch line: estimated fish, then the weighed 31 g.
    expect(find.textContaining(', 31 g'), findsOneWidget);
  });

  appTest('a sample opens filled in and saves as a correction', (
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
    final l1 = await BatchRepository(db, session).stockBatch(
      StockInput(
        code: 'L26-01',
        pondId: e1,
        date: DateTime(2026, 3, 1),
        count: 1000,
        avgWeightMg: 15000,
      ),
    );
    final id = await ReadingRepository(db, session).addSample(
      SampleInput(
        batchId: l1,
        pondId: e1,
        date: DateTime(2026, 3, 15),
        fishCount: 40,
        totalWeightG: 6080,
      ),
    );
    await tester.pumpAndSettle();
    appContainer(tester)
        .read(routerProvider)
        .push('/sample/$e1?batchId=$l1&sampleId=$id');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '40'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '6,08'), findsOneWidget);
    expect(find.text('15/03/2026'), findsOneWidget);
    await enterAndSettle(tester, field('Poissons pesés'), '38');
    await tapAndSettle(tester, find.text('Enregistrer'));
    final current = await (db.select(
      db.samples,
    )..where((s) => s.supersedesId.isNotNull())).getSingle();
    expect((current.supersedesId, current.fishCount), (id, 38));
    expect(current.totalWeightG, 6080);
  });
}
