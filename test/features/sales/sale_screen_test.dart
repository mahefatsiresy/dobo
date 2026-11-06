import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import 'sales_fixtures.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  appTest('a sale lists under its harvest with customer and form', (
    tester,
    db,
  ) async {
    final farm = await SalesFarm.create(db);
    await farm.harvest();
    final c = await farm.customer('Marché Antsirabe');
    await farm.open(tester, '/more/batches/${farm.l1}');
    await tapAndSettle(tester, find.text('Vendre'));
    await tapAndSettle(tester, find.byKey(const ValueKey('sale-customer')));
    await tapAndSettle(tester, find.text('Marché Antsirabe').last);
    await enterAndSettle(tester, field('Poids vendu'), '200');
    await tapAndSettle(tester, find.text('Frais'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(
      find.textContaining('Marché Antsirabe · Frais · 200 kg'),
      findsOneWidget,
    );
    final s = await db.select(db.sales).getSingle();
    expect(
      (s.customerId, s.batchId, s.weightG, s.form),
      (c, farm.l1, 200000, ProductForm.fresh),
    );
  });

  appTest('selling more than the harvest warns but saves', (tester, db) async {
    final farm = await SalesFarm.create(db);
    await farm.harvest(kg: 240);
    await farm.customer('Marché Antsirabe');
    await farm.open(tester, '/more/batches/${farm.l1}/sell');
    await tapAndSettle(tester, find.byKey(const ValueKey('sale-customer')));
    await tapAndSettle(tester, find.text('Marché Antsirabe').last);
    await enterAndSettle(tester, field('Poids vendu'), '300');
    await tapAndSettle(tester, find.text('Vivant'));
    expect(
      find.text('Plus que le poids récolté pas encore vendu (240 kg)'),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect((await db.select(db.sales).getSingle()).weightG, 300000);
  });
}
