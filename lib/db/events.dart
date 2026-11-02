import 'package:drift/drift.dart';

import 'database.dart';
import 'ids.dart';
import 'repositories/errors.dart';
import 'session.dart';
import 'sync_columns.dart';
import 'sync_state.dart';

/// True for event rows that are the current version: not a tombstone, and
/// not superseded by any row of the same table (SPEC §7). Two rows that
/// supersede the same record (two phones correcting it offline) are both
/// current; later milestones flag them.
Expression<bool> isCurrentEvent(TableInfo<Table, Object?> table) {
  final t = table.aliasedName;
  final source = table.actualTableName;
  return CustomExpression<bool>(
    '("$t"."is_tombstone" = 0 AND "$t"."id" NOT IN '
    '(SELECT "supersedes_id" FROM "$source" '
    'WHERE "supersedes_id" IS NOT NULL))',
  );
}

/// Corrections and deletions for append-only event tables: both insert a
/// new row and never touch the old one.
extension EventWrites on AppDatabase {
  /// Inserts [replacement] as the new version of [oldId]; returns its id.
  /// Throws [StaleEventException] when [oldId] is no longer current.
  Future<String> supersede<T extends Table, D>(
    TableInfo<T, D> table,
    String oldId,
    Insertable<D> replacement,
  ) => transaction(() async {
    await _currentOrThrow(table, oldId);
    return _insertNew(table, {
      ...replacement.toColumns(true),
      'supersedes_id': Variable<String>(oldId),
      'is_tombstone': const Variable<bool>(false),
    });
  });

  /// Marks [id] deleted with a copy of it flagged as a tombstone, written by
  /// [session]; returns the tombstone's id. Throws [StaleEventException]
  /// when [id] is no longer current.
  Future<String> tombstone<T extends Table, D extends DataClass>(
    TableInfo<T, D> table,
    String id,
    Session session,
  ) => transaction(() async {
    final target = await _currentOrThrow(table, id);
    return _insertNew(table, {
      ...(target as Insertable<D>).toColumns(false),
      'supersedes_id': Variable<String>(id),
      'is_tombstone': const Variable<bool>(true),
      'entered_by': Variable<String>(session.userId),
      'observed_by': const Variable<String>(null),
      'device_id': Variable<String>(session.deviceId),
      'server_received_at': const Variable<DateTime>(null),
      'server_seq': const Variable<int>(null),
      'sync_state': Variable<String>(SyncState.pending.name),
      'sync_error': const Variable<String>(null),
    });
  });

  /// [id] and every id it supersedes, back to the first version.
  Future<Set<String>> chainIds<T extends Table, D>(
    TableInfo<T, D> table,
    String id,
  ) async {
    final source = table.actualTableName;
    final rows = await customSelect(
      'WITH RECURSIVE chain(id, sup) AS ('
      'SELECT id, supersedes_id FROM "$source" WHERE id = ? '
      'UNION SELECT t.id, t.supersedes_id FROM "$source" t '
      'JOIN chain c ON t.id = c.sup) SELECT id FROM chain',
      variables: [Variable<String>(id)],
      readsFrom: {table},
    ).get();
    return {for (final r in rows) r.read<String>('id')};
  }

  Future<D> _currentOrThrow<T extends Table, D>(
    TableInfo<T, D> table,
    String id,
  ) async {
    final row =
        await (select(table)..where(
              (t) => (t as SyncedRow).id.equals(id) & isCurrentEvent(table),
            ))
            .getSingleOrNull();
    if (row == null) throw StaleEventException(id);
    return row;
  }

  /// Inserts [columns] as a new row with a fresh id and device timestamp.
  Future<String> _insertNew<T extends Table, D>(
    TableInfo<T, D> table,
    Map<String, Expression> columns,
  ) async {
    final id = newId();
    await into(table).insert(
      RawValuesInsertable<D>({
        ...columns,
        'id': Variable<String>(id),
        'created_at_device': Variable<DateTime>(utcNow()),
      }),
    );
    return id;
  }
}
