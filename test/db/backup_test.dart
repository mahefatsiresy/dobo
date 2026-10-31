import 'dart:io';

import 'package:dobo/db/backup.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'default/generated/schema_v3.dart' as v3;

void main() {
  late Directory dir;
  late AppDatabase a;
  late AppDatabase b;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = await Directory.systemTemp.createTemp('dobo-backup-test');
    a = AppDatabase(NativeDatabase(File('${dir.path}/a.sqlite')));
    b = AppDatabase(NativeDatabase(File('${dir.path}/b.sqlite')));
  });
  tearDown(() async {
    await a.close();
    await b.close();
    await dir.delete(recursive: true);
  });

  Future<Map<String, String>> meta(AppDatabase db) async => {
    for (final r in await db.select(db.localMeta).get()) r.key: r.value,
  };

  Future<void> pond(
    AppDatabase db,
    String associationId, {
    String code = 'E1',
    required DateTime updatedAt,
    SyncState state = SyncState.pending,
  }) => db
      .into(db.ponds)
      .insert(
        PondsCompanion.insert(
          id: const Value('p1'),
          associationId: associationId,
          enteredBy: 'm1',
          deviceId: 'dA',
          updatedAtDevice: Value(updatedAt),
          siteId: 's1',
          code: code,
          colour: PondColour.blue,
          role: PondRole.growout,
          syncState: Value(state),
        ),
        mode: InsertMode.insertOrReplace,
      );

  Future<void> logs(AppDatabase db, String associationId, int n) =>
      db.batch((batch) {
        for (var i = 0; i < n; i++) {
          batch.insert(
            db.dailyLogs,
            DailyLogsCompanion.insert(
              associationId: associationId,
              enteredBy: 'm1',
              deviceId: 'dA',
              recordedAt: DateTime.utc(2026, 3, 1, 9),
              pondId: 'p1',
              feedGivenG: 600,
              syncState: Value(i.isEven ? SyncState.pending : SyncState.synced),
            ),
          );
        }
      });

  test('a backup restores a broken phone\'s records and session on an empty '
      'phone', () async {
    final s = await SetupRepository(a)
        .completeSetup(siteName: 'Ambohidratrimo');
    await pond(a, s.associationId, updatedAt: DateTime.utc(2026, 3, 1));
    await logs(a, s.associationId, 4);
    final file = await exportBackup(a, dir);
    expect(file.path, contains('dobo-'));

    final result = await importBackup(b, file);
    expect(result.added, 1 + 1 + 4); // site, pond, logs
    final restored = (await SetupRepository(b).currentSession())!;
    expect(
      (restored.associationId, restored.userId, restored.siteId),
      (s.associationId, s.userId, s.siteId),
    );
    expect(restored.deviceId, isNot(await a.deviceId()));
    final states = (await b.select(b.dailyLogs).get())
        .map((l) => l.syncState)
        .toList();
    expect(states.where((x) => x == SyncState.pending), hasLength(2));
    expect(states.where((x) => x == SyncState.synced), hasLength(2));
    expect((await b.select(b.dailyLogs).get()).first.deviceId, 'dA');

    final again = await importBackup(b, file);
    expect((again.added, again.updated), (0, 0));
  });

  test('a newer local edit is kept, an older one replaced', () async {
    final s = await SetupRepository(a)
        .completeSetup(siteName: 'Ambohidratrimo');
    await SetupRepository(b).completeSetup(siteName: 'Ambohidratrimo', ids: s);
    await pond(
      a,
      s.associationId,
      code: 'A',
      updatedAt: DateTime.utc(2026, 3, 2),
    );
    await pond(
      b,
      s.associationId,
      code: 'B',
      updatedAt: DateTime.utc(2026, 3, 3),
    );
    final file = await exportBackup(a, dir);
    var result = await importBackup(b, file);
    expect(result.updated, 0);
    expect((await b.select(b.ponds).getSingle()).code, 'B');

    await pond(
      b,
      s.associationId,
      code: 'B',
      updatedAt: DateTime.utc(2026, 3, 1),
    );
    result = await importBackup(b, file);
    expect(result.updated, 1);
    expect((await b.select(b.ponds).getSingle()).code, 'A');
  });

  test(
    'a backup from another association is refused, nothing changes',
    () async {
      final sa = await SetupRepository(a).completeSetup(siteName: 'A');
      await logs(a, sa.associationId, 2);
      await SetupRepository(b).completeSetup(siteName: 'B');
      final before = await meta(b);
      final file = await exportBackup(a, dir);
      await expectLater(
        importBackup(b, file),
        throwsA(
          isA<BackupRefused>().having(
            (e) => e.code,
            'code',
            'other_association',
          ),
        ),
      );
      expect(await meta(b), before);
      expect(await b.select(b.dailyLogs).get(), isEmpty);
    },
  );

  test('a backup from an older app version is migrated and imported', () async {
    final old = File('${dir.path}/old.sqlite');
    final v3db = v3.DatabaseAtV3(NativeDatabase(old));
    for (final (k, v) in [
      ('association_id', 'a1'),
      ('user_id', 'm1'),
      ('site_id', 's1'),
      ('device_id', 'dOld'),
    ]) {
      await v3db
          .into(v3db.localMeta)
          .insert(v3.LocalMetaData(key: k, value: v));
    }
    await v3db
        .into(v3db.ponds)
        .insert(
          const v3.PondsData(
            id: 'p1',
            associationId: 'a1',
            enteredBy: 'm1',
            createdAtDevice: '2026-03-01T09:00:00.000Z',
            deviceId: 'dOld',
            syncState: 'pending',
            updatedAtDevice: '2026-03-01T09:00:00.000Z',
            siteId: 's1',
            code: 'E1',
            colour: 'blue',
            structure: 'earth',
            role: 'growout',
            status: 'empty',
            archived: 0,
          ),
        );
    await v3db.close();

    final result = await importBackup(b, old);
    expect(result.added, 1);
    expect((await b.select(b.ponds).getSingle()).code, 'E1');
    expect((await meta(b))['device_id'], isNot('dOld'));
  });

  test('a file that is not a backup is refused', () async {
    final text = File('${dir.path}/notes.txt')..writeAsStringSync('hello');
    await expectLater(
      importBackup(b, text),
      throwsA(
        isA<BackupRefused>().having((e) => e.code, 'code', 'not_a_backup'),
      ),
    );
    expect(await meta(b), isEmpty);
  });
}
