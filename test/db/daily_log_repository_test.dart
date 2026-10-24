import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
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
  });
  tearDown(() => db.close());

  DailyLogInput day(DateTime date, {int feedG = 4000, int deaths = 0}) =>
      DailyLogInput(
        pondId: e1,
        date: date,
        feedGivenG: feedG,
        deaths: deaths,
        leftover: Leftover.some,
        warningSigns: const {WarningSign.rubbing},
      );

  test('saving the same pond-day twice keeps one current log', () async {
    final first = await logs.save(day(DateTime(2026, 3, 1)));
    final second = await logs.save(day(DateTime(2026, 3, 1), feedG: 4500));
    final current = await logs.forDay(e1, DateTime(2026, 3, 1));
    expect(
      (current!.id, current.feedGivenG, current.supersedesId),
      (second, 4500, first),
    );
    expect(current.warningSigns, {WarningSign.rubbing});
    expect(
      await logs.watchRange(DateTime(2026, 3, 1), DateTime(2026, 3, 1)).first,
      hasLength(1),
    );
  });

  test('two days are two logs', () async {
    await logs.save(day(DateTime(2026, 3, 1)));
    await logs.save(day(DateTime(2026, 3, 2)));
    expect(
      await logs.watchRange(DateTime(2026, 3, 1), DateTime(2026, 3, 7)).first,
      hasLength(2),
    );
    expect(await logs.watchLoggedPondsOn(DateTime(2026, 3, 2)).first, {e1});
    expect(await logs.watchLoggedPondsOn(DateTime(2026, 3, 3)).first, isEmpty);
  });

  test('the last log before a day', () async {
    await logs.save(day(DateTime(2026, 3, 1), feedG: 1000));
    await logs.save(day(DateTime(2026, 3, 3), feedG: 3000));
    expect((await logs.lastBefore(e1, DateTime(2026, 3, 3)))!.feedGivenG, 1000);
    expect(await logs.lastBefore(e1, DateTime(2026, 3, 1)), isNull);
  });

  test('negative feed or deaths are refused', () async {
    await expectLater(
      logs.save(day(DateTime(2026, 3, 1), feedG: -1)),
      throwsArgumentError,
    );
    await expectLater(
      logs.save(day(DateTime(2026, 3, 1), deaths: -1)),
      throwsArgumentError,
    );
    expect(await db.select(db.dailyLogs).get(), isEmpty);
  });

  test('deaths lower the fish in the pond', () async {
    await BatchRepository(
      db,
      session,
    ).stockBatch(stockInput('L26-01', pondId: e1));
    await logs.save(day(DateTime(2026, 3, 2), deaths: 30));
    expect((await currentPlacements(db)).single.live.count, 970);
  });

  test('a deleted log no longer counts', () async {
    await BatchRepository(
      db,
      session,
    ).stockBatch(stockInput('L26-01', pondId: e1));
    final id = await logs.save(day(DateTime(2026, 3, 2), deaths: 30));
    await logs.delete(id);
    expect((await currentPlacements(db)).single.live.count, 1000);
    expect(await logs.forDay(e1, DateTime(2026, 3, 2)), isNull);
  });

  test('a week saves in one go, with whose sheet it was', () async {
    await logs.saveWeek([
      DailyLogInput(
        pondId: e1,
        date: DateTime(2026, 3, 30),
        feedGivenG: 3000,
        observedBy: 'p-rakoto',
      ),
      DailyLogInput(
        pondId: e1,
        date: DateTime(2026, 3, 31),
        feedGivenG: 3100,
        observedBy: 'p-rakoto',
      ),
    ]);
    final rows = await db.select(db.dailyLogs).get();
    expect(rows.map((r) => r.observedBy).toSet(), {'p-rakoto'});
    expect(rows, hasLength(2));
  });

  test('records carry the open visit', () async {
    final inVisit = DailyLogRepository(db, session, visitId: 'v1');
    await inVisit.save(day(DateTime(2026, 3, 1)));
    expect((await db.select(db.dailyLogs).getSingle()).visitId, 'v1');
  });
}
