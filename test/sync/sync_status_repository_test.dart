import 'package:dobo/db/database.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/sync_status_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SyncStatusRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SyncStatusRepository(db);
  });
  tearDown(() => db.close());

  Future<void> log(String id) => db
      .into(db.dailyLogs)
      .insert(
        DailyLogsCompanion.insert(
          id: Value(id),
          associationId: 'a1',
          enteredBy: 'm1',
          deviceId: 'd1',
          recordedAt: DateTime.utc(2026, 3, 1, 9),
          pondId: 'p1',
          feedGivenG: 600,
        ),
      );

  Future<void> mark(String id, SyncState state, [String? error]) =>
      (db.update(db.dailyLogs)..where((l) => l.id.equals(id))).write(
        DailyLogsCompanion(syncState: Value(state), syncError: Value(error)),
      );

  test('the counts follow inserts and state changes', () async {
    expect(await repo.watchCounts().first, (pending: 0, rejected: 0));
    await log('l1');
    await log('l2');
    await db
        .into(db.ponds)
        .insert(
          PondsCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            siteId: 's1',
            code: 'E1',
            colour: PondColour.blue,
            role: PondRole.growout,
          ),
        );
    expect(await repo.watchCounts().first, (pending: 3, rejected: 0));
    await mark('l1', SyncState.rejected, '42501: refused');
    await mark('l2', SyncState.synced);
    expect(await repo.watchCounts().first, (pending: 1, rejected: 1));
  });

  test('a refused row is listed with its code and message', () async {
    await log('l1');
    await mark('l1', SyncState.rejected, '42501: new row violates policy');
    final rejected = await repo.watchRejected().first;
    expect(rejected, hasLength(1));
    final r = rejected.single;
    expect((r.table, r.id), ('daily_logs', 'l1'));
    expect((r.errorCode, r.errorMessage), ('42501', 'new row violates policy'));
    expect(r.recordedOrUpdatedAt, DateTime.utc(2026, 3, 1, 9));
  });

  test('the last sync time is read back', () async {
    expect(await repo.watchLastSyncAt().first, isNull);
    await db
        .into(db.localMeta)
        .insert(
          LocalMetaCompanion.insert(
            key: 'last_sync_at',
            value: '2026-03-01T12:00:00.000Z',
          ),
        );
    expect(await repo.watchLastSyncAt().first, DateTime.utc(2026, 3, 1, 12));
  });
}
