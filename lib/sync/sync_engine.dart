import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/ids.dart';
import '../db/sync_state.dart';
import 'row_codec.dart';
import 'sync_api.dart';
import 'sync_tables.dart';

/// Counts from one sync.
class SyncReport {
  const SyncReport({
    required this.pushed,
    required this.rejected,
    required this.pulled,
  });

  final int pushed;
  final int rejected;
  final int pulled;
}

/// Pushes this phone's pending rows, then pulls what the server has that
/// the phone doesn't (SPEC §7; plan Decision 10). Every batch is committed
/// as it is acknowledged, so a dropped network keeps the progress made.
class SyncEngine {
  SyncEngine(this.db, this.api, {this.pushBatch = 200, this.pullLimit = 500});

  final AppDatabase db;
  final SyncApi api;
  final int pushBatch;
  final int pullLimit;

  static const lastSyncKey = 'last_sync_at';
  static String cursorKey(String table) => 'pull_cursor:$table';

  /// Throws [SyncOffline] or [SyncSignedOut] from the [api]; whatever was
  /// acknowledged before stays acknowledged.
  Future<SyncReport> run() async {
    var pushed = 0, rejected = 0, pulled = 0;
    final tables = syncTables(db);
    for (final t in tables) {
      final (ok, refused) = await _push(t);
      pushed += ok;
      rejected += refused;
    }
    for (final t in tables) {
      pulled += await _pull(t);
    }
    await _setMeta(lastSyncKey, utcNow().toIso8601String());
    return SyncReport(pushed: pushed, rejected: rejected, pulled: pulled);
  }

  /// Puts every refused row back in the queue; returns how many.
  Future<int> retryRejected() => db.transaction(() async {
    var n = 0;
    for (final t in syncTables(db)) {
      n += await db.customUpdate(
        'UPDATE "${t.name}" SET sync_state = ?, sync_error = NULL '
        'WHERE sync_state = ?',
        variables: [
          Variable(SyncState.pending.name),
          Variable(SyncState.rejected.name),
        ],
        updates: {t.info},
      );
    }
    return n;
  });

  Future<(int, int)> _push(SyncTable t) async {
    var ok = 0, refused = 0;
    var afterRowId = 0;
    while (true) {
      // By rowid, so rows left pending in this run (edited in flight) are
      // not picked up again and the loop ends.
      final batch = await db
          .customSelect(
            'SELECT rowid AS _rowid, * FROM "${t.name}" '
            'WHERE sync_state = ? AND rowid > ? ORDER BY rowid LIMIT ?',
            variables: [
              Variable(SyncState.pending.name),
              Variable(afterRowId),
              Variable(pushBatch),
            ],
          )
          .get();
      if (batch.isEmpty) return (ok, refused);
      afterRowId = batch.last.data['_rowid']! as int;
      final sent = {for (final r in batch) r.data['id']! as String: r.data};
      final outcomes = await api.push(t.name, [
        for (final row in sent.values) toServer(t, row),
      ]);
      await db.transaction(() async {
        for (final o in outcomes) {
          final row = sent[o.id];
          if (row == null) continue;
          if (await _acknowledge(t, row, o)) {
            o.accepted ? ok++ : refused++;
          }
        }
      });
    }
  }

  /// Marks [row] synced or rejected, unless it changed since it was read:
  /// then it stays pending and goes out next time. True when marked.
  Future<bool> _acknowledge(
    SyncTable t,
    Map<String, Object?> row,
    PushOutcome o,
  ) async {
    final unchanged = t.kind == RowKind.reference
        ? ' AND updated_at_device = ?'
        : '';
    final n = await db.customUpdate(
      'UPDATE "${t.name}" SET sync_state = ?, sync_error = ?, '
      'server_seq = coalesce(?, server_seq), '
      'server_received_at = coalesce(?, server_received_at) '
      'WHERE id = ? AND sync_state = ?$unchanged',
      variables: [
        Variable(o.accepted ? SyncState.synced.name : SyncState.rejected.name),
        Variable(o.accepted ? null : '${o.errorCode}: ${o.errorMessage}'),
        Variable(o.serverSeq),
        Variable(o.serverReceivedAt?.toUtc()),
        Variable(o.id),
        Variable(SyncState.pending.name),
        if (t.kind == RowKind.reference)
          Variable(row['updated_at_device']! as String),
      ],
      updates: {t.info},
    );
    return n > 0;
  }

  Future<int> _pull(SyncTable t) async {
    var pulled = 0;
    var cursor = int.parse(await _meta(cursorKey(t.name)) ?? '0');
    while (true) {
      final rows = await api.pull(t.name, afterSeq: cursor, limit: pullLimit);
      if (rows.isEmpty) return pulled;
      await db.transaction(() async {
        for (final json in rows) {
          await _apply(t, json);
          cursor = json['server_seq']! as int;
        }
        await _setMeta(cursorKey(t.name), '$cursor');
      });
      pulled += rows.length;
      if (rows.length < pullLimit) return pulled;
    }
  }

  /// Events are inserted once. A reference row replaces the phone's copy
  /// only when that copy is synced: a pending or rejected local edit stays.
  Future<void> _apply(SyncTable t, Map<String, Object?> json) async {
    if (t.kind == RowKind.reference) {
      final local = await db
          .customSelect(
            'SELECT sync_state FROM "${t.name}" WHERE id = ?',
            variables: [Variable(json['id']! as String)],
          )
          .getSingleOrNull();
      if (local != null && local.data['sync_state'] != SyncState.synced.name) {
        return;
      }
    }
    final values = fromServer(t, json);
    final conflict = t.kind == RowKind.event ? 'IGNORE' : 'REPLACE';
    await db.customInsert(
      'INSERT OR $conflict INTO "${t.name}" '
      '(${values.keys.map((k) => '"$k"').join(', ')}) '
      'VALUES (${List.filled(values.length, '?').join(', ')})',
      variables: values.values.toList(),
      updates: {t.info},
    );
  }

  Future<String?> _meta(String key) async => (await (db.select(
    db.localMeta,
  )..where((m) => m.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _setMeta(String key, String value) => db
      .into(db.localMeta)
      .insert(
        LocalMetaCompanion.insert(key: key, value: value),
        mode: InsertMode.insertOrReplace,
      );
}
