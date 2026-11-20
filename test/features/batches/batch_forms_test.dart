import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/facts_repository.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/details_fold.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/notice.dart';
import 'package:dobo/features/common/pond_choice.dart';
import 'package:dobo/l10n/formatting.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

/// The demo farm with a ready pond P3, then [path] opened.
void _formTest(
  String description,
  String Function(DemoFarm farm, Map<String, String> batches) path,
  Future<void> Function(WidgetTester tester, AppDatabase db, DemoFarm farm)
  body, {
  Size size = const Size(360, 780),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final farm = await seedDemoFarm(db);
  final session = (await SetupRepository(db).currentSession())!;
  final ponds = PondRepository(db, session);
  farm['P3'] = await ponds.create(
    const PondInput(
      code: 'P3',
      colour: PondColour.purple,
      role: PondRole.growout,
      lengthM: 25,
      widthM: 20,
    ),
  );
  await ponds.setStatus(farm['P3']!, PondStatus.ready);
  final batches = {
    for (final b in await db.select(db.batches).get()) b.code: b.id,
  };
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go(path(farm, batches));
  await tester.pumpAndSettle();
  await body(tester, db, farm);
});

const _wide = Size(480, 900);

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Finder _pinned(String label) => find.descendant(
  of: find.byType(SafeArea),
  matching: find.widgetWithText(FilledButton, label),
);

Finder _snack(String text) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(text));

Future<String> _stockingOf(AppDatabase db, String batchId) async =>
    (await (db.select(
      db.stockings,
    )..where((s) => s.batchId.equals(batchId))).getSingle()).id;

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _formTest(
    'stock from the list: ready ponds first, pond buttons',
    (_, _) => '/stock',
    (tester, db, farm) async {
      expect(find.byType(PondChoice), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.byType(Notice), findsNothing);
      final p3 = tester.getTopLeft(find.byKey(ValueKey('pond-${farm['P3']}')));
      final p1 = tester.getTopLeft(find.byKey(ValueKey('pond-${farm['P1']}')));
      expect(p3.dy < p1.dy || (p3.dy == p1.dy && p3.dx < p1.dx), isTrue);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('pond-${farm['P1']}')),
          matching: find.text('En préparation'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey('pond-${farm['P3']}')),
          matching: find.text('Prêt'),
        ),
        findsNothing,
      );
    },
  );

  _formTest(
    'stock from a pond: the pond is a header',
    (farm, _) => '/stock?pondId=${farm['P3']}',
    (tester, db, farm) async {
      expect(find.byType(PondChoice), findsNothing);
      expect(find.text('P3'), findsOneWidget);
    },
  );

  _formTest(
    'stock: the batch identity details are folded',
    (farm, _) => '/stock?pondId=${farm['P3']}',
    (tester, db, farm) async {
      expect(find.byType(DetailsFold), findsOneWidget);
      expect(_field('Code du lot'), findsOneWidget);
      expect(_field('Écloserie'), findsNothing);
      await tapAndSettle(tester, find.text('Plus de détails'));
      expect(_field('Écloserie'), findsOneWidget);
    },
  );

  _formTest(
    'stock: a density out of range is a band under the count',
    (farm, _) => '/stock?pondId=${farm['P3']}',
    (tester, db, farm) async {
      await enterAndSettle(tester, _field("Nombre d'alevins"), '50000');
      await enterAndSettle(tester, _field('Poids moyen'), '15');
      final band = find.widgetWithText(
        AttentionBand,
        'Densité au-dessus du maximum conseillé',
      );
      expect(band, findsOneWidget);
      expect(
        tester.getTopLeft(band).dy,
        greaterThan(tester.getBottomLeft(_field("Nombre d'alevins")).dy),
      );
      await enterAndSettle(tester, _field("Nombre d'alevins"), '1500');
      expect(find.byType(AttentionBand), findsNothing);
      expect(find.textContaining('Densité après'), findsOneWidget);
    },
  );

  _formTest(
    'stock: Empoissonner saves and says Empoissonné',
    (farm, _) => '/stock?pondId=${farm['P3']}',
    (tester, db, farm) async {
      await enterAndSettle(tester, _field("Nombre d'alevins"), '1500');
      await enterAndSettle(tester, _field('Poids moyen'), '15');
      await tapAndSettle(tester, _pinned('Empoissonner'));
      expect(_snack('Empoissonné'), findsOneWidget);
      expect(
        await (db.select(
          db.stockings,
        )..where((s) => s.pondId.equals(farm['P3']!))).get(),
        hasLength(1),
      );
    },
    // The batch page before step 7's Task 7 needs more than 360 dp.
    size: _wide,
  );

  _formTest(
    'stock correction: named delete, the batch page survives',
    (farm, batches) => '/more/batches/${batches['L-E1']}',
    (tester, db, farm) async {
      final batch = (await (db.select(
        db.batches,
      )..where((b) => b.code.equals('L-E1'))).getSingle()).id;
      final stocking = await _stockingOf(db, batch);
      appContainer(tester)
          .read(routerProvider)
          .go('/more/batches/$batch/stockings/$stocking/edit');
      await tester.pumpAndSettle();
      expect(_pinned('Enregistrer la correction'), findsOneWidget);
      await tapAndSettle(tester, find.byIcon(Icons.more_vert));
      await tapAndSettle(tester, find.text('Supprimer'));
      expect(
        find.text(
          "Supprimer l'empoissonnement du 05/03/2026 "
          '(${formatCount(1240, const Locale('fr'))} poissons, E1) ? '
          'Le lot perd ces poissons.',
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
      expect(tester.takeException(), isNull);
      expect(
        (await currentEvents(
          db,
          db.stockings,
        ).get()).where((s) => s.batchId == batch),
        isEmpty,
      );
    },
    // The batch page before step 7's Task 7 needs more than 360 dp.
    size: _wide,
  );

  _formTest(
    'batch edit: details open when filled; Enregistrer le lot',
    (_, batches) => '/more/batches/${batches['L-E1']}/edit',
    (tester, db, farm) async {
      expect(_field('Code du lot'), findsOneWidget);
      expect(find.text('Récolte prévue (facultatif)'), findsOneWidget);
      expect(_field('Écloserie'), findsNothing);
      expect(_pinned('Enregistrer le lot'), findsOneWidget);
      final session = (await SetupRepository(db).currentSession())!;
      final id = (await (db.select(
        db.batches,
      )..where((b) => b.code.equals('L-E2'))).getSingle()).id;
      await BatchRepository(
        db,
        session,
      ).updateBatch(id, const BatchInput(code: 'L-E2', hatchery: 'Ivato'));
      await tester.pumpAndSettle();
      appContainer(tester).read(routerProvider).go('/more/batches/$id/edit');
      await tester.pumpAndSettle();
      expect(_field('Écloserie'), findsOneWidget);
    },
    // The batch page before step 7's Task 7 needs more than 360 dp.
    size: _wide,
  );

  _formTest(
    'transfer: destination buttons, the isolated band under them',
    (farm, batches) =>
        '/transfer?batchId=${batches['L-E1']}&fromPondId=${farm['E1']}',
    (tester, db, farm) async {
      expect(find.byType(PondChoice), findsOneWidget);
      expect(find.byKey(ValueKey('pond-${farm['E1']}')), findsNothing);
      await tapAndSettle(tester, find.byKey(ValueKey('pond-${farm['E4']}')));
      final band = find.widgetWithText(
        AttentionBand,
        "L'étang de destination est isolé",
      );
      expect(band, findsOneWidget);
      expect(
        tester.getTopLeft(band).dy,
        greaterThan(tester.getBottomLeft(find.byType(PondChoice)).dy),
      );
      await tapAndSettle(tester, find.byKey(ValueKey('pond-${farm['P3']}')));
      await enterAndSettle(tester, _field('Nombre de poissons'), '300');
      await tapAndSettle(tester, _pinned('Transférer'));
      expect(_snack('Transféré'), findsOneWidget);
      final t = await db.select(db.transfers).getSingle();
      expect((t.toPondId, t.count), (farm['P3'], 300));
    },
    // The batch page before step 7's Task 7 needs more than 360 dp.
    size: _wide,
  );

  _formTest(
    'transfer correction: named delete',
    (farm, batches) =>
        '/transfer?batchId=${batches['L-E1']}&fromPondId=${farm['E1']}',
    (tester, db, farm) async {
      await tapAndSettle(tester, find.byKey(ValueKey('pond-${farm['P3']}')));
      await enterAndSettle(tester, _field('Nombre de poissons'), '300');
      await tapAndSettle(tester, _pinned('Transférer'));
      final t = await db.select(db.transfers).getSingle();
      appContainer(tester)
          .read(routerProvider)
          .go('/more/batches/${t.batchId}/transfers/${t.id}/edit');
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.byIcon(Icons.more_vert));
      await tapAndSettle(tester, find.text('Supprimer'));
      expect(
        find.text(
          'Supprimer le transfert du 15/03/2026 (300 poissons, E1 → P3) ? '
          'Les poissons comptent de nouveau dans E1.',
        ),
        findsOneWidget,
      );
    },
    // The batch page before step 7's Task 7 needs more than 360 dp.
    size: _wide,
  );

  for (final (name, path)
      in <(String, String Function(DemoFarm, Map<String, String>))>[
        ('stock', (f, _) => '/stock'),
        (
          'transfer',
          (f, b) => '/transfer?batchId=${b['L-E1']}&fromPondId=${f['E1']}',
        ),
        ('batch edit', (_, b) => '/more/batches/${b['L-E1']}/edit'),
      ]) {
    _formTest('$name: large Malagasy text does not overflow', path, (
      tester,
      db,
      farm,
    ) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.byType(DetailsFold));
      expect(tester.takeException(), isNull);
    });
  }

  _formTest('stock form golden', (_, _) => '/stock', (tester, db, farm) async {
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stock_form_fr.png'),
    );
  });

  _formTest(
    'transfer form golden',
    (farm, batches) =>
        '/transfer?batchId=${batches['L-E1']}&fromPondId=${farm['E1']}',
    (tester, db, farm) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.byKey(ValueKey('pond-${farm['E4']}')));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/transfer_form_mg.png'),
      );
    },
  );
}
