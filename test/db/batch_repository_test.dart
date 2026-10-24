import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/errors.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late PondRepository ponds;
  late BatchRepository batches;
  late String q1, e1, e2;

  setUp(() async {
    (db, session) = await setUpFarm();
    ponds = PondRepository(db, session);
    batches = BatchRepository(db, session);
    q1 = await ponds.create(pondInput('Q1', role: PondRole.quarantine));
    e1 = await ponds.create(pondInput('E1'));
    e2 = await ponds.create(pondInput('E2'));
  });
  tearDown(() => db.close());

  Future<Batch> batch(String id) =>
      (db.select(db.batches)..where((b) => b.id.equals(id))).getSingle();
  Future<BatchSummary> summaryOf(String id) async =>
      (await batches.watchAll().first).singleWhere((s) => s.batch.id == id);

  test('stocking a quarantine pond starts the batch in quarantine', () async {
    final l1 = await batches.stockBatch(stockInput('L26-01', pondId: q1));
    expect((await batch(l1)).status, BatchStatus.quarantine);
    expect((await ponds.get(q1)).status, PondStatus.stocked);
    final st = await db.select(db.stockings).getSingle();
    expect(
      (st.enteredBy, st.deviceId, st.count, st.avgWeightMg),
      (session.userId, session.deviceId, 1000, 12500),
    );
    expect(st.recordedAt, DateTime.utc(2026, 3, 1, 9));
  });

  test('stocking another pond starts the batch active', () async {
    final l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
    expect((await batch(l1)).status, BatchStatus.active);
  });

  test('leaving quarantine activates the batch and empties the pond', () async {
    final l1 = await batches.stockBatch(stockInput('L26-01', pondId: q1));
    await batches.transfer(moveInput(l1, from: q1, to: e1, count: 1000));
    expect((await batch(l1)).status, BatchStatus.active);
    expect((await ponds.get(q1)).status, PondStatus.empty);
    expect((await ponds.get(e1)).status, PondStatus.stocked);
  });

  test('a partial move keeps the source pond stocked', () async {
    final l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
    await batches.transfer(moveInput(l1, from: e1, to: e2, count: 300));
    expect((await ponds.get(e1)).status, PondStatus.stocked);
    final counts = {
      for (final p in await batches.watchPlacements().first)
        p.pondId: p.live.count,
    };
    expect(counts, {e1: 700, e2: 300});
  });

  test(
    'moves to the same pond, of no fish, or out of isolation are refused',
    () async {
      final l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
      await expectLater(
        batches.transfer(moveInput(l1, from: e1, to: e1, count: 10)),
        throwsArgumentError,
      );
      await expectLater(
        batches.transfer(moveInput(l1, from: e1, to: e2, count: 0)),
        throwsArgumentError,
      );
      await ponds.setStatus(e1, PondStatus.isolated);
      await expectLater(
        batches.transfer(moveInput(l1, from: e1, to: e2, count: 10)),
        throwsA(isA<PondIsolatedException>()),
      );
      expect(await db.select(db.transfers).get(), isEmpty);
    },
  );

  test('a refused stocking leaves nothing behind', () async {
    await expectLater(
      batches.stockBatch(stockInput('L26-02', pondId: e2, count: 0)),
      throwsArgumentError,
    );
    await expectLater(
      batches.stockBatch(stockInput('L26-02', pondId: e2, avgWeightMg: 0)),
      throwsArgumentError,
    );
    expect(await db.select(db.batches).get(), isEmpty);
    expect((await ponds.get(e2)).status, PondStatus.empty);
  });

  test('a duplicate batch code is refused', () async {
    await batches.stockBatch(stockInput('L26-01', pondId: e1));
    await expectLater(
      batches.stockBatch(stockInput(' l26-01', pondId: e2)),
      throwsA(isA<DuplicateCodeException>()),
    );
    expect((await ponds.get(e2)).status, PondStatus.empty);
  });

  test('correcting the stocking corrects the batch', () async {
    final l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
    final st1 = (await summaryOf(l1)).firstStocking!.id;
    final st2 = await batches.correctStocking(
      st1,
      StockingCorrection(
        pondId: e1,
        date: DateTime(2026, 3, 2),
        count: 900,
        avgWeightMg: 13000,
      ),
    );
    final s = await summaryOf(l1);
    expect(
      (s.liveCount, s.firstStocking!.id, s.firstStocking!.avgWeightMg),
      (900, st2, 13000),
    );
  });

  test('a deleted stocking leaves the batch with no fish', () async {
    final l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
    await batches.deleteStocking((await summaryOf(l1)).firstStocking!.id);
    final s = await summaryOf(l1);
    expect((s.firstStocking, s.liveCount), (null, 0));
    expect(await batches.watchPlacements().first, isEmpty);
  });

  test('corrected and deleted moves', () async {
    final l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
    final m = await batches.transfer(
      moveInput(l1, from: e1, to: e2, count: 300),
    );
    final m2 = await batches.correctTransfer(
      m,
      moveInput(l1, from: e1, to: e2, count: 200),
    );
    expect((await summaryOf(l1)).liveCount, 1000);
    final counts = {
      for (final p in await batches.watchPlacements().first)
        p.pondId: p.live.count,
    };
    expect(counts, {e1: 800, e2: 200});
    await batches.deleteTransfer(m2);
    expect(
      [for (final p in await batches.watchPlacements().first) p.pondId],
      [e1],
    );
  });

  test('history lists current events, newest first', () async {
    final l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
    await batches.transfer(moveInput(l1, from: e1, to: e2, count: 300));
    final h = await batches.watchHistory(l1).first;
    expect(h.map((e) => e.runtimeType), [TransferEvent, StockingEvent]);
  });

  test('editing a batch keeps its stocking', () async {
    final l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
    await batches.updateBatch(
      l1,
      BatchInput(
        code: 'L26-01',
        strain: 'GIFT',
        monosex: true,
        plannedHarvestOn: DateTime(2026, 9, 1),
      ),
    );
    final b = await batch(l1);
    expect(
      (b.strain, b.monosex, b.plannedHarvestOn),
      ('GIFT', true, DateTime.utc(2026, 9, 1, 9)),
    );
    expect((await summaryOf(l1)).liveCount, 1000);
  });

  test('batch codes follow L<yy>-<nn> per year', () async {
    expect(batches.suggestBatchCode(const [], DateTime(2026, 3, 1)), 'L26-01');
    final l1 = await batches.stockBatch(stockInput('L26-07', pondId: e1));
    final l2 = await batches.stockBatch(stockInput('L25-12', pondId: e2));
    final all = [await batch(l1), await batch(l2)];
    expect(batches.suggestBatchCode(all, DateTime(2026, 3, 1)), 'L26-08');
    expect(batches.suggestBatchCode(all, DateTime(2027, 1, 1)), 'L27-01');
  });
}
