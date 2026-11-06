import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import 'sales_fixtures.dart';

void main() {
  appTest('a new customer appears in the sale picker', (tester, db) async {
    final farm = await SalesFarm.create(db);
    await farm.harvest();
    await farm.open(tester, '/more/batches/${farm.l1}/sell');
    await tapAndSettle(tester, find.text('Nouveau client'));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Nom'),
      'Hôtel Soa',
    );
    await tapAndSettle(tester, find.text('Restaurant'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Vente L26-01'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sale-customer')),
        matching: find.text('Hôtel Soa'),
      ),
      findsOneWidget,
    );
    final c = await db.select(db.customers).getSingle();
    expect((c.name, c.type), ('Hôtel Soa', CustomerType.restaurant));
  });

  appTest('Ventes lists harvests and leads to the customers', (
    tester,
    db,
  ) async {
    final farm = await SalesFarm.create(db);
    await farm.harvest();
    await farm.customer('Marché Antsirabe');
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Ventes'));
    expect(find.textContaining('L26-01'), findsWidgets);
    await tapAndSettle(tester, find.text('Clients'));
    expect(find.text('Marché Antsirabe'), findsOneWidget);
  });

  appTest('Ventes is not in More without the sales flag', (tester, db) async {
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Plus'));
    expect(find.text('Ventes'), findsNothing);
  }, isSales: false);
}
