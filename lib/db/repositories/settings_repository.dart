import 'package:drift/drift.dart';

import '../database.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';

/// Per-site overrides of farming numbers (SPEC F14), synced like any
/// reference row.
class SettingsRepository {
  SettingsRepository(this.db, this.session);

  final AppDatabase db;
  final Session session;

  /// The site's overrides that hold a value.
  Stream<Map<String, num>> watch() =>
      (db.select(db.settingOverrides)..where(
            (o) => o.siteId.equals(session.siteId) & o.value.isNotNull(),
          ))
          .watch()
          .map((rows) => {for (final o in rows) o.key: o.value!});

  Future<void> set(String key, num value) => _write(key, value.toDouble());

  /// Back to the DOMAIN value; synced like any edit.
  Future<void> clear(String key) => _write(key, null);

  Future<void> _write(String key, double? value) => db.transaction(() async {
    final id = settingOverrideId(session.siteId, key);
    final updated =
        await (db.update(
          db.settingOverrides,
        )..where((o) => o.id.equals(id))).write(
          SettingOverridesCompanion(
            value: Value(value),
            deviceId: Value(session.deviceId),
            updatedAtDevice: Value(utcNow()),
            syncState: const Value(SyncState.pending),
          ),
        );
    if (updated > 0) return;
    await db
        .into(db.settingOverrides)
        .insert(
          SettingOverridesCompanion.insert(
            id: Value(id),
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            siteId: session.siteId,
            key: key,
            value: Value(value),
          ),
        );
  });
}
