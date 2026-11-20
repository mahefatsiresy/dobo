import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/facts_repository.dart';
import 'package:dobo/db/repositories/harvest_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/choice_buttons.dart';
import 'package:dobo/features/common/details_fold.dart';
import 'package:dobo/features/common/estimated.dart';
import 'package:dobo/features/common/pond_choice.dart';
import 'package:dobo/l10n/formatting.dart';
import 'package:dobo/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../golden_fonts.dart';
import '../../helpers.dart';
import 'sales_fixtures.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Finder _pinned(String label) => find.descendant(
  of: find.byType(SafeArea),
  matching: find.widgetWithText(FilledButton, label),
);

Finder _snack(String text) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(text));

String _n(int v) => formatCount(v, const Locale('fr'));

void _salesTest(
  String description,
  Future<void> Function(WidgetTester tester, SalesFarm farm) body, {
  Size size = const Size(480, 900),
}) => appTest(description, isSales: true, (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await body(tester, await SalesFarm.create(db));
});

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _salesTest('harvest: the only pond is picked; weight before count', (
    tester,
    farm,
  ) async {
    await farm.open(tester, '/more/batches/${farm.l1}/harvest');
    expect(find.byType(PondChoice), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    final e1 = find.byKey(ValueKey('pond-${farm.e1}'));
    expect(
      tester.widget<OutlinedButton>(e1).style?.backgroundColor?.resolve({}),
      isNot(Colors.white),
    );
    expect(
      tester.getTopLeft(_field('Poids total')).dy,
      lessThan(tester.getTopLeft(_field('Nombre de poissons')).dy),
    );
    expect(find.text(approx('${_n(1000)} poissons dans E1')), findsOneWidget);
  });

  _salesTest('harvest: two ponds, none picked until tapped', (
    tester,
    farm,
  ) async {
    await BatchRepository(farm.db, farm.session).transfer(
      TransferInput(
        batchId: farm.l1,
        fromPondId: farm.e1,
        toPondId: farm.e2,
        date: DateTime(2026, 4, 1),
        count: 400,
      ),
    );
    await farm.open(tester, '/more/batches/${farm.l1}/harvest');
    expect(find.byKey(ValueKey('pond-${farm.e1}')), findsOneWidget);
    expect(find.byKey(ValueKey('pond-${farm.e2}')), findsOneWidget);
    expect(find.textContaining('poissons dans'), findsNothing);
    await tapAndSettle(tester, find.byKey(ValueKey('pond-${farm.e2}')));
    expect(find.text(approx('400 poissons dans E2')), findsOneWidget);
  });

  _salesTest('harvest: missing fish is a band; Récolter says Récolté', (
    tester,
    farm,
  ) async {
    await farm.open(tester, '/more/batches/${farm.l1}/harvest');
    await enterAndSettle(tester, _field('Poids total'), '230');
    await enterAndSettle(tester, _field('Nombre de poissons'), '950');
    await tapAndSettle(tester, find.text("Finale (l'étang est vidé)"));
    final band = find.byType(AttentionBand);
    expect(band, findsOneWidget);
    expect(tester.widget<AttentionBand>(band).severity, BandSeverity.warning);
    expect(
      tester.getTopLeft(band).dy,
      greaterThan(tester.getBottomLeft(_field('Nombre de poissons')).dy),
    );
    await tapAndSettle(tester, _pinned('Récolter'));
    expect(_snack('Récolté'), findsOneWidget);
    expect(await farm.db.select(farm.db.harvests).get(), hasLength(1));
  });

  _salesTest('harvest correction: refused while it has sales, named after', (
    tester,
    farm,
  ) async {
    final h = await farm.harvest(isFinal: false);
    final c = await farm.customer('Marché Anosy');
    for (final day in [2, 3]) {
      await farm.harvests.sell(
        SaleInput(
          harvestId: h,
          customerId: c,
          date: DateTime(2026, 6, day),
          weightG: 10000,
          form: ProductForm.fresh,
        ),
      );
    }
    await farm.open(tester, '/more/batches/${farm.l1}/harvests/$h/edit');
    expect(_pinned('Enregistrer la correction'), findsOneWidget);
    await tapAndSettle(tester, find.byIcon(Icons.more_vert));
    await tapAndSettle(tester, find.text('Supprimer'));
    expect(find.text("Supprimez d'abord ses 2 ventes."), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await currentEvents(farm.db, farm.db.harvests).get(), hasLength(1));
  });

  _salesTest('harvest without sales: the delete names it', (
    tester,
    farm,
  ) async {
    final h = await farm.harvest(isFinal: false);
    await farm.open(tester, '/more/batches/${farm.l1}/harvests/$h/edit');
    await tapAndSettle(tester, find.byIcon(Icons.more_vert));
    await tapAndSettle(tester, find.text('Supprimer'));
    expect(
      find.text(
        'Supprimer la récolte du 01/06/2026 (240 kg, E1) ? '
        'Les poissons comptent de nouveau dans E1.',
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
    expect(await currentEvents(farm.db, farm.db.harvests).get(), isEmpty);
  });

  _salesTest('sale: a preset harvest is a header with what is left', (
    tester,
    farm,
  ) async {
    final h = await farm.harvest(isFinal: false);
    final c = await farm.customer('Marché Anosy');
    await farm.harvests.sell(
      SaleInput(
        harvestId: h,
        customerId: c,
        date: DateTime(2026, 6, 2),
        weightG: 235000,
        form: ProductForm.fresh,
      ),
    );
    await farm.open(tester, '/more/batches/${farm.l1}/sell?harvestId=$h');
    expect(find.textContaining('reste 5 kg'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await enterAndSettle(tester, _field('Poids vendu'), '6');
    final band = find.widgetWithText(
      AttentionBand,
      'Plus que le poids récolté pas encore vendu (5 kg)',
    );
    expect(band, findsOneWidget);
    expect(
      tester.getTopLeft(band).dy,
      greaterThan(tester.getBottomLeft(_field('Poids vendu')).dy),
    );
  });

  _salesTest('sale: the customer picker puts recent buyers first', (
    tester,
    farm,
  ) async {
    final h = await farm.harvest(isFinal: false);
    await farm.customer('Ando');
    final zo = await farm.customer('Zo');
    await farm.harvests.sell(
      SaleInput(
        harvestId: h,
        customerId: zo,
        date: DateTime(2026, 6, 2),
        weightG: 1000,
        form: ProductForm.fresh,
      ),
    );
    await farm.open(tester, '/more/batches/${farm.l1}/sell?harvestId=$h');
    await tapAndSettle(tester, find.text('Client'));
    expect(
      tester.getTopLeft(find.text('Zo')).dy,
      lessThan(tester.getTopLeft(find.text('Ando')).dy),
    );
    await tapAndSettle(tester, find.text('Nouveau client'));
    await enterAndSettle(tester, _field('Nom'), 'Hôtel Soa');
    await tapAndSettle(tester, find.text('Restaurant'));
    await tapAndSettle(tester, _pinned('Ajouter le client'));
    expect(find.text('Vente L26-01'), findsOneWidget);
    expect(find.text('Hôtel Soa'), findsOneWidget);
  });

  _salesTest('sale: form buttons, note folded, Vendre says Vendu', (
    tester,
    farm,
  ) async {
    final h = await farm.harvest(isFinal: false);
    final c = await farm.customer('Marché Anosy');
    await farm.open(tester, '/more/batches/${farm.l1}/sell?harvestId=$h');
    expect(find.byType(ChoiceButtons<ProductForm>), findsOneWidget);
    expect(_field('Bon de livraison (facultatif)'), findsNothing);
    expect(find.byType(DetailsFold), findsOneWidget);
    await enterAndSettle(tester, _field('Poids vendu'), '40');
    await tapAndSettle(tester, find.text('Client'));
    await tapAndSettle(tester, find.text('Marché Anosy'));
    await tapAndSettle(tester, find.text('Frais'));
    await tapAndSettle(tester, _pinned('Vendre'));
    expect(_snack('Vendu'), findsOneWidget);
    final sale = await farm.db.select(farm.db.sales).getSingle();
    expect((sale.customerId, sale.weightG), (c, 40000));
  });

  _salesTest('sale correction: filled in, corrected, named delete', (
    tester,
    farm,
  ) async {
    final h = await farm.harvest(isFinal: false);
    final c = await farm.customer('Marché Anosy');
    final s = await farm.harvests.sell(
      SaleInput(
        harvestId: h,
        customerId: c,
        date: DateTime(2026, 6, 2),
        weightG: 40000,
        form: ProductForm.fresh,
      ),
    );
    await farm.open(tester, '/more/batches/${farm.l1}/sales/$s/edit');
    expect(find.text('40'), findsOneWidget);
    await enterAndSettle(tester, _field('Poids vendu'), '35');
    await tapAndSettle(tester, _pinned('Enregistrer la correction'));
    expect(
      (await currentEvents(farm.db, farm.db.sales).getSingle()).weightG,
      35000,
    );
    final current = (await currentEvents(
      farm.db,
      farm.db.sales,
    ).getSingle()).id;
    await farm.open(tester, '/more/batches/${farm.l1}/sales/$current/edit');
    await tapAndSettle(tester, find.byIcon(Icons.more_vert));
    await tapAndSettle(tester, find.text('Supprimer'));
    expect(
      find.text(
        'Supprimer la vente du 02/06/2026 (35 kg, Marché Anosy) ? '
        'Ces kilos restent à vendre.',
      ),
      findsOneWidget,
    );
  });

  _salesTest('customer form: type buttons, contact folded, ⋮ to remove', (
    tester,
    farm,
  ) async {
    await farm.open(tester, '/more/sales/customers/new');
    expect(find.byType(ChoiceButtons<CustomerType>), findsOneWidget);
    expect(_field('Contact (facultatif)'), findsNothing);
    expect(_pinned('Ajouter le client'), findsOneWidget);
    final c = await farm.customer('Marché Anosy');
    await farm.open(tester, '/more/sales/customers/$c');
    expect(_pinned('Enregistrer le client'), findsOneWidget);
    await tapAndSettle(tester, find.byIcon(Icons.more_vert));
    expect(find.text('Retirer de la liste'), findsOneWidget);
  });

  for (final page in ['harvest', 'sale', 'customer']) {
    _salesTest('$page: large Malagasy text does not overflow', (
      tester,
      farm,
    ) async {
      final h = await farm.harvest(isFinal: false);
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await farm.open(tester, switch (page) {
        'harvest' => '/more/batches/${farm.l1}/harvest',
        'sale' => '/more/batches/${farm.l1}/sell?harvestId=$h',
        _ => '/more/sales/customers/new',
      });
      expect(tester.takeException(), isNull);
    }, size: const Size(360, 780));
  }

  _salesTest('sale form golden', (tester, farm) async {
    final h = await farm.harvest(isFinal: false);
    await farm.open(tester, '/more/batches/${farm.l1}/sell?harvestId=$h');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sale_form_fr.png'),
    );
  }, size: const Size(360, 780));

  _salesTest('harvest form golden', (tester, farm) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    await farm.open(tester, '/more/batches/${farm.l1}/harvest');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/harvest_form_mg.png'),
    );
  }, size: const Size(360, 780));
}
