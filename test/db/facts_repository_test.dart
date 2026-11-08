import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/facts_repository.dart';
import 'package:dobo/db/repositories/harvest_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late DailyLogRepository logs;
  late String e1;

  setUp(() async {
    (db, session) = await setUpFarm();
    logs = DailyLogRepository(db, session);
    e1 = await PondRepository(db, session).create(pondInput('E1'));
    await BatchRepository(db, session).stockBatch(stockInput('L1', pondId: e1));
  });
  tearDown(() => db.close());

  DailyLogInput day(DateTime date, {int feedG = 4000, int deaths = 0}) =>
      DailyLogInput(
        pondId: e1,
        date: date,
        feedGivenG: feedG,
        deaths: deaths,
        warningSigns: const {WarningSign.rubbing},
        deathSigns: const {WarningSign.whiteSpots},
        waterColour: WaterColour.darkGreen,
      );

  test('currentFacts excludes superseded and tombstoned logs', () async {
    await logs.save(day(DateTime(2026, 3, 2), feedG: 1000));
    await logs.save(day(DateTime(2026, 3, 2), feedG: 2000, deaths: 4));
    final gone = await logs.save(day(DateTime(2026, 3, 3)));
    await logs.delete(gone);

    final f = await currentFacts(db);
    expect(f.stockings, hasLength(1));
    final l = f.logs.single;
    expect((l.pondId, l.feedG, l.deaths), (e1, 2000, 4));
    expect(l.signs, {WarningSign.rubbing, WarningSign.whiteSpots});
    expect(l.waterColour, WaterColour.darkGreen);
  });

  test('currentFacts carries enteredBy and observedBy', () async {
    await logs.save(
      DailyLogInput(
        pondId: e1,
        date: DateTime(2026, 3, 2),
        feedGivenG: 1000,
        observedBy: 'p1',
      ),
    );
    final l = (await currentFacts(db)).logs.single;
    expect(l.enteredBy, session.userId);
    expect(l.observedBy, 'p1');
  });

  test('currentFacts carries the note', () async {
    await logs.save(
      DailyLogInput(
        pondId: e1,
        date: DateTime(2026, 3, 2),
        feedGivenG: 1000,
        note: 'Digue fuit',
      ),
    );
    expect((await currentFacts(db)).logs.single.note, 'Digue fuit');
  });

  test('watchFarmFacts emits again after a daily log is saved', () async {
    final stream = watchFarmFacts(db);
    final seen = <int>[];
    final sub = stream.listen((f) => seen.add(f.logs.length));
    await pumpEventQueue();
    await logs.save(day(DateTime(2026, 3, 2)));
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 1);
  });

  test('harvests and log lots reach FarmFacts', () async {
    final batchId = (await db.select(db.batches).getSingle()).id;
    await HarvestRepository(db, session).harvest(
      HarvestInput(
        batchId: batchId,
        pondId: e1,
        date: DateTime(2026, 6, 1),
        count: 100,
        weightG: 25000,
        isFinal: false,
      ),
    );
    await logs.save(
      DailyLogInput(
        pondId: e1,
        date: DateTime(2026, 3, 5),
        feedGivenG: 4000,
        feedLotId: 'lot-1',
      ),
    );
    final f = await currentFacts(db);
    final h = f.harvests.single;
    expect(
      (h.batchId, h.count, h.weightG, h.isFinal),
      (batchId, 100, 25000, false),
    );
    expect(f.logs.single.feedLotId, 'lot-1');
  });
}
