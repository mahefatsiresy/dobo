import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/customer_repository.dart';
import 'package:dobo/db/repositories/harvest_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';

/// E1 and E2, batch L26-01 with 1 000 fish in E1 (stocked 01/03).
class SalesFarm {
  SalesFarm._(this.db, this.session, this.e1, this.e2, this.l1);

  final AppDatabase db;
  final Session session;
  final String e1, e2, l1;

  static Future<SalesFarm> create(AppDatabase db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final e1 = await ponds.create(pondInput('E1'));
    final e2 = await ponds.create(pondInput('E2'));
    final l1 = await BatchRepository(
      db,
      session,
    ).stockBatch(stockInput('L26-01', pondId: e1));
    return SalesFarm._(db, session, e1, e2, l1);
  }

  HarvestRepository get harvests => HarvestRepository(db, session);

  Future<String> harvest({
    int count = 950,
    int kg = 240,
    bool isFinal = true,
  }) => harvests.harvest(
    HarvestInput(
      batchId: l1,
      pondId: e1,
      date: DateTime(2026, 6, 1),
      count: count,
      weightG: kg * 1000,
      isFinal: isFinal,
    ),
  );

  Future<String> customer(String name) => CustomerRepository(
    db,
    session,
  ).create(CustomerInput(name: name, type: CustomerType.market));

  Future<void> open(WidgetTester tester, String path) async {
    await tester.pumpAndSettle();
    appContainer(tester).read(routerProvider).go(path);
    await tester.pumpAndSettle();
  }
}
