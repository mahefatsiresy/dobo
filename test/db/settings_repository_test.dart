import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/settings_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  const session = Session(
    associationId: 'a1',
    userId: 'm1',
    deviceId: 'd1',
    siteId: '0190d5a0-0000-7000-8000-0000000000c1',
    isAdmin: true,
  );

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('an override is set, changed and cleared on one row per key', () async {
    final repo = SettingsRepository(db, session);
    await repo.set('minOxygenMgL', 4);
    expect(await repo.watch().first, {'minOxygenMgL': 4});
    await repo.set('minOxygenMgL', 3.5);
    await repo.clear('minOxygenMgL');
    expect(await repo.watch().first, isEmpty);
    final rows = await db.select(db.settingOverrides).get();
    expect(rows, hasLength(1));
    expect(
      (rows.single.value, rows.single.syncState),
      (null, SyncState.pending),
    );
  });

  test('two phones overriding a key write the same row', () async {
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    await SettingsRepository(db, session).set('minOxygenMgL', 4);
    await SettingsRepository(other, session).set('minOxygenMgL', 5);
    final a = await db.select(db.settingOverrides).getSingle();
    final b = await other.select(other.settingOverrides).getSingle();
    expect(a.id, b.id);
  });
}
