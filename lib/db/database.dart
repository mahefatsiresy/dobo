import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/types.dart';
import 'database.steps.dart';
import 'ids.dart';
import 'sync_state.dart';
import 'converters.dart';
import 'tables/batches.dart';
import 'tables/daily_logs.dart';
import 'tables/groups.dart';
import 'tables/health_events.dart';
import 'tables/local_meta.dart';
import 'tables/members.dart';
import 'tables/observations.dart';
import 'tables/people.dart';
import 'tables/samples.dart';
import 'tables/setting_overrides.dart';
import 'tables/ponds.dart';
import 'tables/sites.dart';
import 'tables/stockings.dart';
import 'tables/transfers.dart';
import 'tables/treatments.dart';
import 'tables/visits.dart';
import 'tables/water_readings.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Sites,
    LocalMeta,
    People,
    Ponds,
    Batches,
    Stockings,
    Transfers,
    DailyLogs,
    WaterReadings,
    Samples,
    Observations,
    HealthEvents,
    Treatments,
    Visits,
    Groups,
    Members,
    SettingOverrides,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'dobo'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.people);
        await m.createTable(schema.ponds);
        await m.createTable(schema.batches);
        await m.createTable(schema.stockings);
        await m.createTable(schema.transfers);
      },
      from2To3: (m, schema) async {
        await m.createTable(schema.dailyLogs);
        await m.createTable(schema.waterReadings);
        await m.createTable(schema.samples);
        await m.createTable(schema.observations);
        await m.createTable(schema.healthEvents);
        await m.createTable(schema.treatments);
        await m.createTable(schema.visits);
      },
      from3To4: (m, schema) async {
        await m.createTable(schema.groups);
        await m.createTable(schema.members);
        await m.createTable(schema.settingOverrides);
      },
    ),
  );

  static const _deviceIdKey = 'device_id';

  /// Stable id of this phone, created on first use.
  Future<String> deviceId() => transaction(() async {
    final row = await (select(
      localMeta,
    )..where((m) => m.key.equals(_deviceIdKey))).getSingleOrNull();
    if (row != null) return row.value;
    final id = newId();
    await into(localMeta)
        .insert(LocalMetaCompanion.insert(key: _deviceIdKey, value: id));
    return id;
  });
}
