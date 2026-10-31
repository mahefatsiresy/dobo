import 'package:dobo/db/database.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/sync_api.dart';
import 'package:dobo/sync/sync_engine.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_sync_api.dart';

void main() {
  late AppDatabase a;
  late AppDatabase b;
  late FakeSyncApi server;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    a = AppDatabase(NativeDatabase.memory());
    b = AppDatabase(NativeDatabase.memory());
    server = FakeSyncApi();
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  SyncEngine engine(AppDatabase db) => SyncEngine(db, server);

  Future<void> log(AppDatabase db, String id, {String device = 'dA'}) => db
      .into(db.dailyLogs)
      .insert(
        DailyLogsCompanion.insert(
          id: Value(id),
          associationId: 'a1',
          enteredBy: 'm1',
          deviceId: device,
          recordedAt: DateTime.utc(2026, 3, 1, 9),
          pondId: 'p1',
          feedGivenG: 600,
          deaths: const Value(3),
        ),
      );

  Future<void> pond(AppDatabase db, {String code = 'E1'}) => db
      .into(db.ponds)
      .insert(
        PondsCompanion.insert(
          id: const Value('p1'),
          associationId: 'a1',
          enteredBy: 'm1',
          deviceId: 'dA',
          updatedAtDevice: Value(DateTime.utc(2026, 3, 1, 6)),
          siteId: 's1',
          code: code,
          colour: PondColour.blue,
          role: PondRole.growout,
        ),
      );

  /// A local edit of the pond, as PondRepository makes it.
  Future<void> rename(AppDatabase db, String code, String device, int hour) =>
      (db.update(db.ponds)..where((p) => p.id.equals('p1'))).write(
        PondsCompanion(
          code: Value(code),
          deviceId: Value(device),
          updatedAtDevice: Value(DateTime.utc(2026, 3, 1, hour)),
          syncState: const Value(SyncState.pending),
        ),
      );

  Future<Pond> pondOf(AppDatabase db) => db.select(db.ponds).getSingle();

  Future<Map<SyncState, int>> logStates(AppDatabase db) async {
    final counts = <SyncState, int>{};
    for (final l in await db.select(db.dailyLogs).get()) {
      counts[l.syncState] = (counts[l.syncState] ?? 0) + 1;
    }
    return counts;
  }

  test('a daily log recorded on one phone reaches the other', () async {
    await log(a, 'l1');
    final report = await engine(a).run();
    expect(report.pushed, 1);
    await engine(b).run();

    final onA = await a.select(a.dailyLogs).getSingle();
    final onB = await b.select(b.dailyLogs).getSingle();
    expect(
      (onA.syncState, onB.syncState),
      (SyncState.synced, SyncState.synced),
    );
    expect(onA.serverSeq, isNotNull);
    expect(onB.serverSeq, onA.serverSeq);
    expect((onB.deaths, onB.feedGivenG), (3, 600));
  });

  test('two offline renames: the later sync wins, the other is kept on the '
      'server', () async {
    await pond(a);
    await engine(a).run();
    await engine(b).run();

    await rename(a, 'A1', 'dA', 7);
    await rename(b, 'B1', 'dB', 8);
    await engine(a).run();
    await engine(b).run();
    await engine(a).run();

    expect((await pondOf(a)).code, 'B1');
    expect((await pondOf(b)).code, 'B1');
    expect((await pondOf(a)).syncState, SyncState.synced);
    expect(server.history['ponds']!.map((r) => r['code']), contains('A1'));
  });

  test('Review Focus 1: an edit made while its push is in flight stays '
      'pending and goes out next time', () async {
    await pond(a);
    server.onPush = (table) async {
      if (table == 'ponds') await rename(a, 'E1-edited', 'dA', 9);
    };
    await engine(a).run();
    server.onPush = null;

    final p = await pondOf(a);
    expect((p.code, p.syncState), ('E1-edited', SyncState.pending));
    expect(server.rows['ponds']!['p1']!['code'], 'E1');

    await engine(a).run();
    expect((await pondOf(a)).syncState, SyncState.synced);
    expect(server.rows['ponds']!['p1']!['code'], 'E1-edited');
  });

  test('Review Focus 2: an accepted push whose answer is lost is retried '
      'without duplicates', () async {
    await log(a, 'l1');
    await log(a, 'l2');
    server.loseNextAnswer = true;
    await expectLater(engine(a).run(), throwsA(isA<SyncOffline>()));
    expect(await logStates(a), {SyncState.pending: 2});

    await engine(a).run();
    expect(server.rows['daily_logs'], hasLength(2));
    expect(await logStates(a), {SyncState.synced: 2});
  });

  test('Review Focus 5: weeks offline, the network drops mid-way, the next '
      'sync carries on', () async {
    await a.batch((batch) {
      for (var i = 0; i < 5000; i++) {
        batch.insert(
          a.dailyLogs,
          DailyLogsCompanion.insert(
            id: Value('l${i.toString().padLeft(4, '0')}'),
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'dA',
            recordedAt: DateTime.utc(2026, 1, 1, 9),
            pondId: 'p1',
            feedGivenG: 600,
          ),
        );
      }
    });
    server.failAfterCalls(10);
    await expectLater(engine(a).run(), throwsA(isA<SyncOffline>()));
    expect(await logStates(a), {
      SyncState.synced: 2000,
      SyncState.pending: 3000,
    });

    server.failAfterCalls(1 << 30);
    await engine(a).run();
    expect(await logStates(a), {SyncState.synced: 5000});
    expect(server.rows['daily_logs'], hasLength(5000));
  });

  test(
    'a refused row stays on the phone, marked, and can be retried',
    () async {
      await log(a, 'l1');
      await a
          .into(a.waterReadings)
          .insert(
            WaterReadingsCompanion.insert(
              id: const Value('r1'),
              associationId: 'a1',
              enteredBy: 'm1',
              deviceId: 'dA',
              recordedAt: DateTime.utc(2026, 3, 1, 9),
              pondId: 'p1',
              ph: const Value(7.2),
            ),
          );
      server.refuse('water_readings', '42501');
      final report = await engine(a).run();
      expect((report.pushed, report.rejected), (1, 1));

      final reading = await a.select(a.waterReadings).getSingle();
      expect(reading.syncState, SyncState.rejected);
      expect(reading.syncError, contains('42501'));
      expect(await logStates(a), {SyncState.synced: 1});

      expect(await engine(a).retryRejected(), 1);
      final again = await a.select(a.waterReadings).getSingle();
      expect((again.syncState, again.syncError), (SyncState.pending, null));
    },
  );

  test('a pull never overwrites a local edit not yet sent', () async {
    await pond(a);
    await engine(a).run();
    await engine(b).run();
    await rename(a, 'A1', 'dA', 7);
    await rename(b, 'B1', 'dB', 8);
    server.refuse('ponds', '42501');
    await engine(a).run(); // A's rename refused: stays A1, rejected
    server.rows['ponds']!['p1'] = {
      ...server.rows['ponds']!['p1']!,
      'code': 'X9',
      'server_seq': 999,
    };
    await engine(a).run();
    final p = await pondOf(a);
    expect((p.code, p.syncState), ('A1', SyncState.rejected));
    await engine(b).run(); // B's pending rename refused too: stays B1
    expect((await pondOf(b)).code, 'B1');
  });

  test('last sync time is recorded once push and pull are done', () async {
    await engine(a).run();
    final meta = await (a.select(
      a.localMeta,
    )..where((m) => m.key.equals('last_sync_at'))).getSingleOrNull();
    expect(meta, isNotNull);
  });
}
