import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'ids.dart';
import 'sync_state.dart';
import 'tables/local_meta.dart';
import 'tables/sites.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Sites, LocalMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'dobo'));

  @override
  int get schemaVersion => 1;

  static const _deviceIdKey = 'device_id';

  /// Stable id of this phone, created on first use.
  Future<String> deviceId() => transaction(() async {
        final row = await (select(localMeta)
              ..where((m) => m.key.equals(_deviceIdKey)))
            .getSingleOrNull();
        if (row != null) return row.value;
        final id = newId();
        await into(localMeta)
            .insert(LocalMetaCompanion.insert(key: _deviceIdKey, value: id));
        return id;
      });
}
