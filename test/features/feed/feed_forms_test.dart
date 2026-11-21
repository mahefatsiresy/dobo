import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/facts_repository.dart';
import 'package:dobo/db/repositories/feed_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/choice_buttons.dart';
import 'package:dobo/features/common/details_fold.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

final _now = DateTime.utc(2026, 3, 20, 6);
final _clock = clockProvider.overrideWithValue(() => _now);

Future<String> _lot(AppDatabase db) async =>
    FeedRepository(db, (await SetupRepository(db).currentSession())!).deliver(
      FeedDeliveryInput(
        date: DateTime(2026, 3, 1),
        phase: Phase.growout,
        weightG: 120000,
        manufacturedOn: DateTime(2026, 2, 20),
        label: 'Sacs bleus',
        supplier: 'Provenderie',
      ),
    );

Future<void> _go(WidgetTester tester, String path) async {
  appContainer(tester).read(routerProvider).go(path);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Finder _pinned(String label) => find.descendant(
  of: find.byType(SafeArea),
  matching: find.widgetWithText(FilledButton, label),
);

Finder _snack(String text) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(text));

void main() {
  appTest('a new delivery: phase buttons, details folded', (tester, db) async {
    await _go(tester, '/more/feed/deliver');
    expect(find.byType(ChoiceButtons<Phase>), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(_field('Fournisseur'), findsNothing);
    expect(_field('Marque sur les sacs'), findsNothing);
    await tapAndSettle(tester, find.text('Grossissement'));
    await enterAndSettle(tester, _field('Poids livré'), '25');
    await tapAndSettle(
      tester,
      find.ancestor(
        of: find.text('Date de fabrication'),
        matching: find.byType(InkWell),
      ),
    );
    await tapAndSettle(tester, find.text('OK'));
    await tapAndSettle(tester, _pinned('Enregistrer la livraison'));
    expect(_snack('Livraison enregistrée'), findsOneWidget);
    expect((await db.select(db.feedDeliveries).getSingle()).weightG, 25000);
  }, overrides: [_clock]);

  appTest('a lot opens its delivery to correct', (tester, db) async {
    final id = await _lot(db);
    await _go(tester, '/more/feed/$id');
    expect(find.byType(DetailsFold), findsOneWidget);
    expect(_field('Fournisseur'), findsOneWidget); // filled: open
    expect(find.text('Jeter une partie'), findsOneWidget);
    expect(_pinned('Enregistrer la correction'), findsOneWidget);
    await enterAndSettle(tester, _field('Poids livré'), '100');
    await tapAndSettle(tester, _pinned('Enregistrer la correction'));
    expect(_snack('Correction enregistrée'), findsOneWidget);
    final current = await currentEvents(db, db.feedDeliveries).getSingle();
    expect(current.weightG, 100000);
  }, overrides: [_clock]);

  appTest('deleting a delivery says what the stock loses', (tester, db) async {
    final id = await _lot(db);
    await _go(tester, '/more/feed/$id');
    await tapAndSettle(tester, find.byIcon(Icons.more_vert));
    await tapAndSettle(tester, find.text('Supprimer'));
    expect(
      find.text(
        'Supprimer la livraison du 01/03/2026 (120 kg) ? '
        'Le stock baisse de 120 kg.',
      ),
      findsOneWidget,
    );
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Supprimer'),
      ),
    );
    expect(await currentEvents(db, db.feedDeliveries).get(), isEmpty);
  }, overrides: [_clock]);

  appTest('the delete names the saved delivery, not what was typed', (
    tester,
    db,
  ) async {
    final id = await _lot(db);
    await _go(tester, '/more/feed/$id');
    await enterAndSettle(tester, _field('Poids livré'), '100');
    await tapAndSettle(tester, find.byIcon(Icons.more_vert));
    await tapAndSettle(tester, find.text('Supprimer'));
    expect(find.textContaining('(120 kg)'), findsOneWidget);
  }, overrides: [_clock]);

  appTest('discard: the lot as a header, reason buttons, Jeter', (
    tester,
    db,
  ) async {
    final id = await _lot(db);
    await _go(tester, '/more/feed/$id/discard');
    expect(find.textContaining('Sacs bleus'), findsOneWidget);
    expect(find.byType(ChoiceButtons<DiscardReason>), findsOneWidget);
    await enterAndSettle(tester, _field('Poids jeté'), '5');
    await tapAndSettle(tester, find.text('Moisi'));
    await tapAndSettle(tester, _pinned('Jeter'));
    expect(_snack('Jeté'), findsOneWidget);
    expect((await db.select(db.feedDiscards).getSingle()).weightG, 5000);
  }, overrides: [_clock]);

  for (final page in ['deliver', 'lot', 'discard']) {
    appTest('$page: large Malagasy text does not overflow', (tester, db) async {
      tester.view.physicalSize = const Size(720, 1560);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final id = await _lot(db);
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _go(tester, switch (page) {
        'deliver' => '/more/feed/deliver',
        'lot' => '/more/feed/$id',
        _ => '/more/feed/$id/discard',
      });
      expect(tester.takeException(), isNull);
    }, overrides: [_clock]);
  }
}
