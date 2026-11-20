import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/harvest_repository.dart';
import 'package:dobo/db/repositories/health_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';
import 'sales_fixtures.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> fill(WidgetTester tester, {required String count}) async {
    await enterAndSettle(tester, field('Nombre de poissons'), count);
    await enterAndSettle(tester, field('Poids total'), '237,5');
    await tapAndSettle(tester, find.text("Finale (l'étang est vidé)"));
  }

  appTest('a final harvest under the estimate warns about 50 missing fish', (
    tester,
    db,
  ) async {
    final farm = await SalesFarm.create(db);
    await farm.open(tester, '/more/batches/${farm.l1}');
    await tapAndSettle(tester, find.text('Récolter'));
    expect(find.textContaining('poissons dans E1'), findsOneWidget);
    await fill(tester, count: '950');
    expect(find.textContaining('50 poissons non retrouvés'), findsOneWidget);
  });

  appTest('saving a final harvest closes the batch and empties the pond', (
    tester,
    db,
  ) async {
    final farm = await SalesFarm.create(db);
    await farm.open(tester, '/more/batches/${farm.l1}/harvest');
    await fill(tester, count: '950');
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Récolter'));
    expect(find.text('Clôturé'), findsOneWidget);
    final h = await db.select(db.harvests).getSingle();
    expect(
      (h.pondId, h.count, h.weightG, h.isFinal),
      (farm.e1, 950, 237500, true),
    );
    final e1 = await (db.select(
      db.ponds,
    )..where((p) => p.id.equals(farm.e1))).getSingle();
    expect(e1.status, PondStatus.empty);
  });

  appTest('an isolated pond is not offered', (tester, db) async {
    final farm = await SalesFarm.create(db);
    await BatchRepository(
      db,
      farm.session,
    ).transfer(moveInput(farm.l1, from: farm.e1, to: farm.e2, count: 400));
    await HealthRepository(db, farm.session).report(
      pondId: farm.e1,
      signs: const {},
      isolate: true,
      technicianCalled: false,
    );
    await farm.open(tester, '/more/batches/${farm.l1}/harvest');
    expect(find.byKey(ValueKey('pond-${farm.e2}')), findsOneWidget);
    expect(find.byKey(ValueKey('pond-${farm.e1}')), findsNothing);
  });

  appTest('correcting a final harvest to partial reopens the batch', (
    tester,
    db,
  ) async {
    final farm = await SalesFarm.create(db);
    final h = await farm.harvest(count: 950);
    await farm.open(tester, '/more/batches/${farm.l1}');
    expect(find.text('Clôturé'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(ValueKey('harvest-edit-$h')));
    expect(field('Nombre de poissons'), findsOneWidget);
    expect(find.text('950'), findsOneWidget);
    await tapAndSettle(tester, find.text('Partielle'));
    await tapAndSettle(tester, find.text('Enregistrer la correction'));
    await reveal(tester, find.text('En récolte'));
    expect(find.text('En récolte'), findsOneWidget);
    final current = await db.select(db.harvests).get();
    expect(current.where((r) => r.supersedesId == h), hasLength(1));
  });

  appTest('a harvest with a sale is deleted only once the sale is gone', (
    tester,
    db,
  ) async {
    final farm = await SalesFarm.create(db);
    final h = await farm.harvest();
    final c = await farm.customer('Marché Antsirabe');
    final sale = await farm.harvests.sell(
      SaleInput(
        harvestId: h,
        customerId: c,
        date: DateTime(2026, 6, 1),
        weightG: 100000,
        form: ProductForm.fresh,
      ),
    );
    await farm.open(tester, '/more/batches/${farm.l1}');
    Future<void> confirmDelete(Key key) async {
      await tapAndSettle(tester, find.byKey(key));
      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Supprimer'),
        ),
      );
    }

    await confirmDelete(ValueKey('harvest-delete-$h'));
    expect(find.text("Supprimez d'abord sa vente."), findsOneWidget);
    await confirmDelete(ValueKey('sale-delete-$sale'));
    expect(find.textContaining('Marché Antsirabe'), findsNothing);
    await confirmDelete(ValueKey('harvest-delete-$h'));
    await reveal(tester, find.text('Actif'));
    expect(find.text('Actif'), findsOneWidget);
    expect(find.text('Récoltes et ventes'), findsNothing);
  });
}
