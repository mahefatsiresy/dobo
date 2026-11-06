import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/customer_repository.dart';
import 'package:dobo/db/repositories/errors.dart';
import 'package:dobo/db/repositories/harvest_repository.dart';
import 'package:dobo/db/repositories/health_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/db/repositories/facts_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late PondRepository ponds;
  late BatchRepository batches;
  late HarvestRepository harvests;
  late String e1, e2, l1;

  setUp(() async {
    (db, session) = await setUpFarm();
    ponds = PondRepository(db, session);
    batches = BatchRepository(db, session);
    harvests = HarvestRepository(db, session);
    e1 = await ponds.create(pondInput('E1'));
    e2 = await ponds.create(pondInput('E2'));
    l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
  });
  tearDown(() => db.close());

  Future<BatchStatus> status() async => (await (db.select(
    db.batches,
  )..where((b) => b.id.equals(l1))).getSingle()).status;

  Future<int> liveIn(String pond) async =>
      placementsOf(await currentFacts(db))
          .where((p) => p.pondId == pond)
          .fold<int>(0, (n, p) => n + p.live.count);

  HarvestInput input(String pond, int count, {bool isFinal = false}) =>
      HarvestInput(
        batchId: l1,
        pondId: pond,
        date: DateTime(2026, 6, 1),
        count: count,
        weightG: count * 250,
        isFinal: isFinal,
      );

  test('the first harvest sets harvesting', () async {
    await harvests.harvest(input(e1, 300));
    expect(await status(), BatchStatus.harvesting);
    expect(await liveIn(e1), 700);
  });

  test("a final harvest of the batch's last pond closes it", () async {
    await harvests.harvest(input(e1, 950, isFinal: true));
    expect(await status(), BatchStatus.closed);
    expect(await liveIn(e1), 0);
    expect((await ponds.get(e1)).status, PondStatus.empty);
  });

  test('a final harvest in one of two ponds keeps it harvesting', () async {
    await batches.transfer(moveInput(l1, from: e1, to: e2, count: 400));
    await harvests.harvest(input(e1, 600, isFinal: true));
    expect(await status(), BatchStatus.harvesting);
    expect(await liveIn(e2), 400);
  });

  test('deleting the final harvest reopens the batch and restores the live '
      'count', () async {
    final id = await harvests.harvest(input(e1, 950, isFinal: true));
    await harvests.delete(id);
    expect(await status(), BatchStatus.active);
    expect(await liveIn(e1), 1000);
    expect((await ponds.get(e1)).status, PondStatus.stocked);
  });

  test('correcting a final harvest to partial reopens the batch', () async {
    final id = await harvests.harvest(input(e1, 950, isFinal: true));
    await harvests.correct(id, input(e1, 950));
    expect(await status(), BatchStatus.harvesting);
    expect(await liveIn(e1), 50);
  });

  test('an isolated pond refuses a harvest', () async {
    await HealthRepository(db, session).report(
      pondId: e1,
      signs: const {},
      isolate: true,
      technicianCalled: false,
    );
    await expectLater(
      harvests.harvest(input(e1, 100)),
      throwsA(isA<PondIsolatedException>()),
    );
  });

  test('a sale is listed under its harvest', () async {
    final h = await harvests.harvest(input(e1, 950, isFinal: true));
    final c = await CustomerRepository(db, session).create(
      const CustomerInput(name: 'Marché Antsirabe', type: CustomerType.market),
    );
    await harvests.sell(
      SaleInput(
        harvestId: h,
        customerId: c,
        date: DateTime(2026, 6, 1),
        weightG: 200000,
        form: ProductForm.fresh,
      ),
    );
    final list = await harvests.watchForBatch(l1).first;
    final sale = list.single.sales.single;
    expect(
      (sale.batchId, sale.customerId, sale.weightG, sale.form),
      (l1, c, 200000, ProductForm.fresh),
    );
  });

  test("every batch's harvests, newest first", () async {
    final l2 = await batches.stockBatch(stockInput('L26-02', pondId: e2));
    await harvests.harvest(input(e1, 100));
    await harvests.harvest(
      HarvestInput(
        batchId: l2,
        pondId: e2,
        date: DateTime(2026, 6, 5),
        count: 50,
        weightG: 12500,
        isFinal: false,
      ),
    );
    final all = await harvests.watchAll().first;
    expect(all.map((h) => h.harvest.batchId), [l2, l1]);
  });

  test('a corrected harvest keeps its sales', () async {
    final h = await harvests.harvest(input(e1, 950, isFinal: true));
    final c = await CustomerRepository(
      db,
      session,
    ).create(const CustomerInput(name: 'Marché', type: CustomerType.market));
    await harvests.sell(
      SaleInput(
        harvestId: h,
        customerId: c,
        date: DateTime(2026, 6, 1),
        weightG: 100000,
        form: ProductForm.fresh,
      ),
    );
    await harvests.correct(h, input(e1, 940, isFinal: true));
    final list = await harvests.watchForBatch(l1).first;
    expect(list.single.harvest.count, 940);
    expect(list.single.sales, hasLength(1));
  });
}
