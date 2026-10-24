import 'package:dobo/db/database.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('site gets a UUIDv7 id, pending state and UTC timestamps', () async {
    final id = await db
        .into(db.sites)
        .insert(
          SitesCompanion.insert(
            name: 'Ambohidratrimo',
            associationId: 'a1',
            enteredBy: 'u1',
            deviceId: 'd1',
          ),
        );
    final site = await (db.select(
      db.sites,
    )..where((s) => s.rowId.equals(id))).getSingle();
    expect(site.id[14], '7');
    expect(site.syncState, SyncState.pending);
    expect(site.createdAtDevice.isUtc, isTrue);
    expect(site.serverSeq, isNull);
  });

  test('deviceId is created once and then stable', () async {
    final first = await db.deviceId();
    expect(await db.deviceId(), first);
  });
}
