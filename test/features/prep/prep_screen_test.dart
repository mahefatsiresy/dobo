import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/prep_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';

void main() {
  final now = DateTime.utc(2026, 3, 20, 6); // 09:00 in Madagascar
  final clock = clockProvider.overrideWithValue(() => now);

  /// An empty pond E1, 20 × 15 m unless [surface] is false.
  Future<(String, PrepRepository, PondRepository)> pond(
    AppDatabase db, {
    bool surface = true,
  }) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final id = await ponds.create(
      pondInput(
        'E1',
        lengthM: surface ? 20 : null,
        widthM: surface ? 15 : null,
      ),
    );
    return (id, PrepRepository(db, session), ponds);
  }

  Future<void> openPrep(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Préparation'));
  }

  appTest('a 300 m² pond shows quicklime 30–60 kg and manure 6–9 kg', (
    tester,
    db,
  ) async {
    await pond(db);
    await openPrep(tester);
    expect(find.text('Chaux vive : 30–60 kg pour 300 m²'), findsOneWidget);
    expect(find.text('Fumier : 6–9 kg pour 300 m²'), findsOneWidget);
  }, overrides: [clock]);

  appTest('a pond without a surface shows no dose', (tester, db) async {
    await pond(db, surface: false);
    await openPrep(tester);
    expect(find.textContaining('Chaux vive :'), findsNothing);
    expect(find.textContaining('pas de dose'), findsOneWidget);
  }, overrides: [clock]);

  appTest('Fait records the step today and the pond is in preparation', (
    tester,
    db,
  ) async {
    final (e1, prep, ponds) = await pond(db);
    await openPrep(tester);
    await tapAndSettle(tester, find.byKey(const ValueKey('done-drain')));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Fait le 20/03/2026'), findsOneWidget);
    expect((await prep.progress(e1)).done.keys, [PrepStep.drain]);
    expect((await ponds.get(e1)).status, PondStatus.preparing);
  }, overrides: [clock]);

  appTest('a treatment keeps its product and dose', (tester, db) async {
    final (e1, prep, _) = await pond(db);
    await openPrep(tester);
    await tapAndSettle(tester, find.byKey(const ValueKey('done-treat')));
    await tapAndSettle(tester, find.text('Chaux vive'));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Dose utilisée'),
      '45',
    );
    await tapAndSettle(tester, find.text('Enregistrer'));
    final step = (await prep.progress(e1)).done[PrepStep.treat]!;
    expect((step.product, step.doseG), (PrepProduct.quicklime, 45000));
  }, overrides: [clock]);

  appTest('drain then fill shows the dates and enables ready', (
    tester,
    db,
  ) async {
    final (e1, prep, _) = await pond(db);
    await prep.record(e1, PrepStep.drain, on: DateTime(2026, 3, 1));
    await prep.record(e1, PrepStep.fill, on: DateTime(2026, 3, 18));
    await openPrep(tester);
    expect(find.text('Séchage : du 06/03/2026 au 08/03/2026'), findsOneWidget);
    expect(find.text("Repos jusqu'au 20/03/2026"), findsOneWidget);
    final ready = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Prêt à empoissonner'),
    );
    expect(ready.onPressed, isNotNull);
  }, overrides: [clock]);

  appTest('marking ready lists skipped steps, then the pond shows Prêt', (
    tester,
    db,
  ) async {
    final (e1, prep, ponds) = await pond(db);
    await prep.record(e1, PrepStep.drain, on: DateTime(2026, 3, 1));
    await prep.record(e1, PrepStep.fill, on: DateTime(2026, 3, 15));
    await openPrep(tester);
    await tapAndSettle(tester, find.text('Prêt à empoissonner'));
    expect(
      find.textContaining('Assèchement au soleil, Traitement'),
      findsOneWidget,
    );
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Prêt à empoissonner'),
      ),
    );
    expect((await ponds.get(e1)).status, PondStatus.ready);
    await tapAndSettle(tester, find.text('Étangs'));
    expect(find.text('Prêt'), findsOneWidget); // E1's card
  }, overrides: [clock]);

  appTest('a pond with fish shows no Préparation button', (tester, db) async {
    final (e1, _, _) = await pond(db);
    final session = (await SetupRepository(db).currentSession())!;
    await BatchRepository(db, session).stockBatch(stockInput('L1', pondId: e1));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
    expect(find.text('Préparation'), findsNothing);
  }, overrides: [clock]);
}
