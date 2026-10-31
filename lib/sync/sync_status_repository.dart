import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/sync_state.dart';
import 'sync_engine.dart';
import 'sync_tables.dart';

/// A row the server refused, kept on the phone (SPEC §7).
class RejectedRow {
  const RejectedRow({
    required this.table,
    required this.id,
    required this.recordedOrUpdatedAt,
    required this.errorCode,
    required this.errorMessage,
  });

  final String table;
  final String id;
  final DateTime recordedOrUpdatedAt;
  final String errorCode;
  final String errorMessage;
}

/// What the sync badge and the sync screen show.
class SyncStatusRepository {
  SyncStatusRepository(this.db);

  final AppDatabase db;

  Set<ResultSetImplementation<dynamic, dynamic>> get _tables => {
    for (final t in syncTables(db)) t.info,
  };

  /// Unsent and refused rows across every synced table.
  Stream<({int pending, int rejected})> watchCounts() {
    String sum(SyncState s) => syncTables(db)
        .map(
          (t) =>
              '(SELECT count(*) FROM "${t.name}" '
              "WHERE sync_state = '${s.name}')",
        )
        .join(' + ');
    return db
        .customSelect(
          'SELECT ${sum(SyncState.pending)} AS pending, '
          '${sum(SyncState.rejected)} AS rejected',
          readsFrom: _tables,
        )
        .watchSingle()
        .map(
          (r) => (
            pending: r.data['pending']! as int,
            rejected: r.data['rejected']! as int,
          ),
        );
  }

  /// Refused rows, newest first. `sync_error` is "code: message".
  Stream<List<RejectedRow>> watchRejected() {
    final union = syncTables(db)
        .map(
          (t) =>
              "SELECT '${t.name}' AS tbl, id, "
              '${t.kind == RowKind.event ? 'recorded_at' : 'updated_at_device'}'
              ' AS at, sync_error FROM "${t.name}" '
              "WHERE sync_state = '${SyncState.rejected.name}'",
        )
        .join(' UNION ALL ');
    return db
        .customSelect('$union ORDER BY at DESC', readsFrom: _tables)
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              () {
                final error = (r.data['sync_error'] as String?) ?? '';
                final cut = error.indexOf(': ');
                return RejectedRow(
                  table: r.data['tbl']! as String,
                  id: r.data['id']! as String,
                  recordedOrUpdatedAt: DateTime.parse(r.data['at']! as String)
                      .toUtc(),
                  errorCode: cut < 0 ? error : error.substring(0, cut),
                  errorMessage: cut < 0 ? '' : error.substring(cut + 2),
                );
              }(),
          ],
        );
  }

  /// When push and pull last both finished, if ever.
  Stream<DateTime?> watchLastSyncAt() =>
      (db.select(db.localMeta)
            ..where((m) => m.key.equals(SyncEngine.lastSyncKey)))
          .watchSingleOrNull()
          .map((m) => m == null ? null : DateTime.parse(m.value).toUtc());
}
