import 'package:drift/drift.dart';

import '../db/sync_state.dart';
import 'sync_tables.dart';

/// Columns that describe this phone's copy of a row and never leave it. The
/// server sets its own `server_seq` and `server_received_at`.
const localOnlyColumns = {
  'sync_state',
  'sync_error',
  'server_seq',
  'server_received_at',
};

/// A row as SQLite stores it (`SELECT *`) → the JSON the server takes.
/// Booleans become true/false and dates UTC ISO-8601; the rest is already
/// what Postgres expects.
Map<String, Object?> toServer(SyncTable t, Map<String, Object?> sqliteRow) => {
  for (final c in t.info.$columns)
    if (!localOnlyColumns.contains(c.$name))
      c.$name: _out(c.type, sqliteRow[c.$name]),
};

/// [type] is the column's DriftSqlType (its base type isn't exported).
Object? _out(Object type, Object? raw) => switch ((type, raw)) {
  (_, null) => null,
  (DriftSqlType.bool, final int v) => v == 1,
  (DriftSqlType.dateTime, final String v) => DateTime.parse(
    v,
  ).toUtc().toIso8601String(),
  _ => raw,
};

/// A server row → values to insert into this phone's table, marked synced.
/// Keys the phone doesn't have (the server-only `user_id`) are dropped.
Map<String, Variable<Object>> fromServer(
  SyncTable t,
  Map<String, Object?> json,
) => {
  for (final c in t.info.$columns)
    if (json.containsKey(c.$name)) c.$name: _in(c.type, json[c.$name]),
  'sync_state': Variable<String>(SyncState.synced.name),
  'sync_error': const Variable<String>(null),
};

Variable<Object> _in(Object type, Object? v) {
  if (v == null) return const Variable<Object>(null);
  return switch (type) {
    DriftSqlType.dateTime => Variable<DateTime>(
      DateTime.parse(v as String).toUtc(),
    ),
    DriftSqlType.bool => Variable<bool>(v as bool),
    DriftSqlType.int ||
    DriftSqlType.bigInt => Variable<int>((v as num).toInt()),
    DriftSqlType.double => Variable<double>((v as num).toDouble()),
    _ => Variable<String>(v as String),
  };
}
