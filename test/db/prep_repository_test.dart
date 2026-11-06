import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/errors.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/prep_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late PondRepository ponds;
  late PrepRepository prep;
  late String e1;

  setUp(() async {
    (db, session) = await setUpFarm();
    ponds = PondRepository(db, session);
    prep = PrepRepository(db, session);
    e1 = await ponds.create(pondInput('E1'));
  });
  tearDown(() => db.close());

  test('recording drain sets preparing', () async {
    await prep.record(e1, PrepStep.drain, on: DateTime(2026, 3, 1));
    expect((await ponds.get(e1)).status, PondStatus.preparing);
    final p = await prep.progress(e1);
    expect(p.done.keys, [PrepStep.drain]);
  });

  test('a treat step keeps its product and dose', () async {
    await prep.record(
      e1,
      PrepStep.treat,
      on: DateTime(2026, 3, 8),
      product: PrepProduct.quicklime,
      doseG: 45000,
    );
    final row = await db.select(db.prepSteps).getSingle();
    expect((row.product, row.doseG), (PrepProduct.quicklime, 45000));
  });

  test('mark ready records rest and sets ready', () async {
    await prep.record(e1, PrepStep.fill, on: DateTime(2026, 3, 10));
    await prep.markReady(e1, on: DateTime(2026, 3, 12));
    expect((await ponds.get(e1)).status, PondStatus.ready);
    final p = await prep.progress(e1);
    expect(p.done[PrepStep.rest]!.date.day, 12);
  });

  test('rest is only recorded by marking ready', () async {
    await expectLater(
      prep.record(e1, PrepStep.rest, on: DateTime(2026, 3, 12)),
      throwsArgumentError,
    );
  });

  test('a pond with fish refuses a step', () async {
    await BatchRepository(db, session).stockBatch(stockInput('L1', pondId: e1));
    await expectLater(
      prep.record(e1, PrepStep.drain, on: DateTime(2026, 3, 2)),
      throwsA(isA<PondNotEmptyException>()),
    );
  });

  test('a step on a ready pond keeps it ready', () async {
    await prep.record(e1, PrepStep.fill, on: DateTime(2026, 3, 10));
    await prep.markReady(e1, on: DateTime(2026, 3, 12));
    await prep.record(e1, PrepStep.fertilise, on: DateTime(2026, 3, 13));
    expect((await ponds.get(e1)).status, PondStatus.ready);
  });

  test('deleting a step takes it out of the checklist', () async {
    final id = await prep.record(e1, PrepStep.drain, on: DateTime(2026, 3, 1));
    await prep.delete(id);
    expect((await prep.progress(e1)).done, isEmpty);
  });
}
