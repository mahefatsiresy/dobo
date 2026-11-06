import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/customer_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late CustomerRepository customers;

  setUp(() async {
    final (d, session) = await setUpFarm();
    db = d;
    customers = CustomerRepository(db, session);
  });
  tearDown(() => db.close());

  test('archived customers are not offered', () async {
    final a = await customers.create(
      const CustomerInput(name: 'Hôtel Soa', type: CustomerType.restaurant),
    );
    await customers.create(
      const CustomerInput(name: 'Marché', type: CustomerType.market),
    );
    await customers.archive(a);
    final active = await customers.watchActive().first;
    expect(active.map((c) => c.name), ['Marché']);
  });

  test('an update renames and stays pending for sync', () async {
    final a = await customers.create(
      const CustomerInput(name: 'Marche', type: CustomerType.market),
    );
    await customers.update(
      a,
      const CustomerInput(
        name: 'Marché Antsirabe',
        type: CustomerType.market,
        contact: '034 00 000 00',
      ),
    );
    final c = await db.select(db.customers).getSingle();
    expect((c.name, c.contact), ('Marché Antsirabe', '034 00 000 00'));
  });
}
