import 'package:dobo/db/database.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/row_codec.dart';
import 'package:dobo/sync/sync_tables.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  SyncTable table(String name) =>
      syncTables(db).singleWhere((t) => t.name == name);

  Future<Map<String, Object?>> rawRow(String name) async =>
      (await db.customSelect('SELECT * FROM "$name"').getSingle()).data;

  test('every table but the device-only ones is synced, in push order', () {
    expect(syncTables(db).map((t) => t.name), [
      'groups',
      'members',
      'sites',
      'people',
      'ponds',
      'batches',
      'visits',
      'setting_overrides',
      'customers',
      'stockings',
      'transfers',
      'daily_logs',
      'water_readings',
      'samples',
      'observations',
      'health_events',
      'treatments',
      'visit_reports',
      'photos',
      'prep_steps',
      'feed_deliveries',
      'feed_discards',
      'harvests',
      'sales',
    ]);
    expect(
      syncTables(db).map((t) => t.name).toSet(),
      db.allTables.map((t) => t.actualTableName).toSet()
        ..removeAll(['local_meta', 'report_reads', 'photo_uploads']),
    );
    expect(table('ponds').kind, RowKind.reference);
    expect(table('daily_logs').kind, RowKind.event);
    expect(table('customers').kind, RowKind.reference);
    expect(table('sales').kind, RowKind.event);
  });

  test(
    'a daily log goes to the server as JSON without phone-only columns',
    () async {
      await db
          .into(db.dailyLogs)
          .insert(
            DailyLogsCompanion.insert(
              id: const Value('l1'),
              associationId: 'a1',
              enteredBy: 'm1',
              deviceId: 'd1',
              recordedAt: DateTime.utc(2026, 3, 1, 12),
              pondId: 'p1',
              feedGivenG: 600,
              ateFast: const Value(true),
              warningSigns: const Value({WarningSign.rubbing}),
            ),
          );
      final json = toServer(table('daily_logs'), await rawRow('daily_logs'));
      expect(json, containsPair('ate_fast', true));
      expect(json, containsPair('is_tombstone', false));
      expect(json, containsPair('warning_signs', 'rubbing'));
      expect(json, containsPair('recorded_at', '2026-03-01T12:00:00.000Z'));
      expect(json, containsPair('feed_given_g', 600));
      expect(json, containsPair('observed_by', null));
      for (final key in localOnlyColumns) {
        expect(json.containsKey(key), false, reason: key);
      }
    },
  );

  test(
    'a server row is stored as synced, its dates as the same instant',
    () async {
      final values = fromServer(table('ponds'), {
        'id': 'p1',
        'association_id': 'a1',
        'entered_by': 'm1',
        'observed_by': null,
        'created_at_device': '2026-03-01T12:00:00+00:00',
        'device_id': 'd1',
        'server_received_at': '2026-03-01T12:00:05.123+00:00',
        'server_seq': 42,
        'updated_at_device': '2026-03-01T15:00:00+03:00',
        'site_id': 's1',
        'code': 'E1',
        'colour': 'blue',
        'structure': 'earth',
        'role': 'growout',
        'water_supply': null,
        'length_m': 25,
        'width_m': 10.5,
        'surface_m2_override': null,
        'depth_inlet_m': null,
        'depth_outlet_m': null,
        'status': 'stocked',
        'archived': false,
      });
      await db.into(db.ponds).insert(RawValuesInsertable<Pond>(values));
      final pond = await db.select(db.ponds).getSingle();
      expect(pond.createdAtDevice, DateTime.utc(2026, 3, 1, 12));
      expect(pond.updatedAtDevice, DateTime.utc(2026, 3, 1, 12));
      expect(pond.serverReceivedAt, DateTime.utc(2026, 3, 1, 12, 0, 5, 123));
      expect((pond.serverSeq, pond.syncState), (42, SyncState.synced));
      expect((pond.lengthM, pond.widthM, pond.archived), (25.0, 10.5, false));
      expect(pond.status, PondStatus.stocked);
    },
  );

  test('server-only keys are dropped', () {
    final values = fromServer(table('members'), {
      'id': 'm1',
      'name': 'Rakoto',
      'user_id': '00000000-0000-0000-0000-0000000000b3',
    });
    expect(values.containsKey('user_id'), false);
    expect(values.containsKey('name'), true);
  });

  test('a row survives the trip to the server and back', () async {
    await db
        .into(db.waterReadings)
        .insert(
          WaterReadingsCompanion.insert(
            id: const Value('r1'),
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            recordedAt: DateTime.utc(2026, 3, 1, 6, 30),
            pondId: 'p1',
            ph: const Value(7.2),
            colour: const Value(WaterColour.darkGreen),
          ),
        );
    final before = await db.select(db.waterReadings).getSingle();
    final t = table('water_readings');
    final json = toServer(t, await rawRow('water_readings'));
    await db.delete(db.waterReadings).go();
    await db
        .into(db.waterReadings)
        .insert(RawValuesInsertable<WaterReading>(fromServer(t, json)));
    final after = await db.select(db.waterReadings).getSingle();
    expect(after, before.copyWith(syncState: SyncState.synced));
  });
}
