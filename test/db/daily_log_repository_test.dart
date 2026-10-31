import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/errors.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/domain/dates.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
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

  test(
    'two current logs for a day (another phone\'s, by sync): newest wins',
    () async {
      final mine = await logs.save(day(DateTime(2026, 3, 1), feedG: 4000));
      // The other phone's log of the same pond-day arrives as a plain row.
      await db
          .into(db.dailyLogs)
          .insert(
            DailyLogsCompanion.insert(
              associationId: session.associationId,
              enteredBy: 'other-user',
              deviceId: 'other-phone',
              createdAtDevice: Value(
                DateTime.now().toUtc().add(const Duration(minutes: 1)),
              ),
              recordedAt: farmDateToUtc(DateTime(2026, 3, 1)),
              pondId: e1,
              feedGivenG: 4500,
            ),
          );
      expect((await logs.forDay(e1, DateTime(2026, 3, 1)))!.feedGivenG, 4500);
      final fixed = await logs.save(day(DateTime(2026, 3, 1), feedG: 4200));
      final current = await logs.forDay(e1, DateTime(2026, 3, 1));
      expect((current!.id, current.feedGivenG), (fixed, 4200));
      expect(mine, isNot(fixed));
    },
  );

  group('duplicate pond-days', () {
    /// Another phone's log of [date], arriving by sync.
    Future<String> otherPhone(DateTime date, {int feedG = 4500}) async {
      final row = await db
          .into(db.dailyLogs)
          .insertReturning(
            DailyLogsCompanion.insert(
              associationId: session.associationId,
              enteredBy: 'other-user',
              deviceId: 'other-phone',
              createdAtDevice: Value(
                DateTime.now().toUtc().add(const Duration(minutes: 1)),
              ),
              recordedAt: farmDateToUtc(date),
              pondId: e1,
              feedGivenG: feedG,
            ),
          );
      return row.id;
    }

    test('watchCurrentForDay lists both, newest first', () async {
      final mine = await logs.save(day(DateTime(2026, 3, 1)));
      final theirs = await otherPhone(DateTime(2026, 3, 1));
      await logs.save(day(DateTime(2026, 3, 2)));
      final both = await logs
          .watchCurrentForDay(e1, DateTime(2026, 3, 1))
          .first;
      expect(both.map((l) => l.id), [theirs, mine]);
    });

    test(
      'keepOnly tombstones the others and writes the kept one again',
      () async {
        final mine = await logs.save(day(DateTime(2026, 3, 1)));
        final theirs = await otherPhone(DateTime(2026, 3, 1));
        final copy = await logs.keepOnly(mine, [theirs]);
        final left = await logs
            .watchCurrentForDay(e1, DateTime(2026, 3, 1))
            .first;
        expect(left.map((l) => (l.id, l.supersedesId)), [(copy, mine)]);
        final kept = (await logs.forDay(e1, DateTime(2026, 3, 1)))!;
        expect(
          (kept.id, kept.feedGivenG, kept.enteredBy),
          (copy, 4000, session.userId),
        );
      },
    );

    test(
      'keepOnly on an already-discarded log throws and writes nothing',
      () async {
        final mine = await logs.save(day(DateTime(2026, 3, 1)));
        final theirs = await otherPhone(DateTime(2026, 3, 1));
        final third = await otherPhone(DateTime(2026, 3, 1), feedG: 4700);
        await logs.delete(theirs);
        final rows = (await db.select(db.dailyLogs).get()).length;
        await expectLater(
          logs.keepOnly(mine, [third, theirs]),
          throwsA(isA<StaleEventException>()),
        );
        expect(await db.select(db.dailyLogs).get(), hasLength(rows));
      },
    );

    test('keeping a log another phone already discarded throws', () async {
      final mine = await logs.save(day(DateTime(2026, 3, 1)));
      final theirs = await otherPhone(DateTime(2026, 3, 1));
      await logs.delete(mine); // the other phone kept theirs, synced here
      await expectLater(
        logs.keepOnly(mine, [theirs]),
        throwsA(isA<StaleEventException>()),
      );
      final left = await logs
          .watchCurrentForDay(e1, DateTime(2026, 3, 1))
          .first;
      expect(left.map((l) => l.id), [theirs]);
    });

    test('two phones keeping opposite logs offline leave both, still '
        'flagged, never none', () async {
      final x = await logs.save(day(DateTime(2026, 3, 1)));
      final y = await otherPhone(DateTime(2026, 3, 1));
      final phoneB = AppDatabase(NativeDatabase.memory());
      addTearDown(phoneB.close);

      /// Sync, as far as daily logs go: each phone gets the other's rows.
      Future<void> exchange() async {
        for (final (from, to) in [(db, phoneB), (phoneB, db)]) {
          final have = {
            for (final r in await to.select(to.dailyLogs).get()) r.id,
          };
          for (final r in await from.select(from.dailyLogs).get()) {
            if (!have.contains(r.id)) await to.into(to.dailyLogs).insert(r);
          }
        }
      }

      await exchange();
      final logsB = DailyLogRepository(
        phoneB,
        Session(
          associationId: session.associationId,
          userId: 'member-b',
          deviceId: 'phone-b',
          siteId: session.siteId,
        ),
      );
      await logs.keepOnly(x, [y]);
      await logsB.keepOnly(y, [x]);
      await exchange();
      for (final phone in [logs, logsB]) {
        final left = await phone
            .watchCurrentForDay(e1, DateTime(2026, 3, 1))
            .first;
        expect(left, hasLength(2));
        expect({for (final l in left) l.feedGivenG}, {4000, 4500});
      }
    });
  });
}
