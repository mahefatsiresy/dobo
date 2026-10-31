import 'package:dobo/sync/sync_api.dart';

/// An in-memory server that behaves like `sync_push` and the pull query:
/// one global seq, events inserted once, reference rows last-write-wins with
/// the overwritten version kept, and a version seen before acknowledged
/// without change (plan Decision 9).
class FakeSyncApi implements SyncApi {
  int _seq = 0;
  int calls = 0;
  int? _failAfter;
  final _refused = <String, String>{};

  /// table → id → row as the server stores it.
  final rows = <String, Map<String, Map<String, Object?>>>{};

  /// table → overwritten versions.
  final history = <String, List<Map<String, Object?>>>{};

  /// Runs during a push, after the rows are read and before the answer.
  Future<void> Function(String table)? onPush;

  /// The next push is applied, then the answer is lost.
  bool loseNextAnswer = false;

  /// Every row pushed to [table] is refused with [code].
  void refuse(String table, String code) => _refused[table] = code;

  /// Calls after the first [n] fail as if the network dropped.
  void failAfterCalls(int n) => _failAfter = n;

  void _call() {
    calls++;
    if (_failAfter != null && calls > _failAfter!) throw SyncOffline();
  }

  static bool _isEvent(Map<String, Object?> row) =>
      row.containsKey('is_tombstone');

  @override
  Future<List<PushOutcome>> push(
    String table,
    List<Map<String, Object?>> pushed,
  ) async {
    _call();
    await onPush?.call(table);
    final stored = rows.putIfAbsent(table, () => {});
    final outcomes = <PushOutcome>[];
    for (final row in pushed) {
      final id = row['id']! as String;
      final code = _refused[table];
      if (code != null) {
        outcomes.add(
          PushOutcome(id: id, errorCode: code, errorMessage: 'refused'),
        );
        continue;
      }
      final current = stored[id];
      if (_isEvent(row)) {
        if (current == null) stored[id] = _stamp(row);
      } else if (!_seen(table, row)) {
        if (current != null) history.putIfAbsent(table, () => []).add(current);
        stored[id] = _stamp(row);
      }
      final now = stored[id]!;
      outcomes.add(
        PushOutcome(
          id: id,
          serverSeq: now['server_seq']! as int,
          serverReceivedAt: DateTime.parse(
            now['server_received_at']! as String,
          ),
        ),
      );
    }
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw SyncOffline();
    }
    return outcomes;
  }

  bool _seen(String table, Map<String, Object?> row) {
    bool same(Map<String, Object?> v) =>
        v['device_id'] == row['device_id'] &&
        v['updated_at_device'] == row['updated_at_device'];
    final current = rows[table]![row['id']];
    return (current != null && same(current)) ||
        (history[table] ?? const []).any(
          (v) => v['id'] == row['id'] && same(v),
        );
  }

  Map<String, Object?> _stamp(Map<String, Object?> row) => {
    ...row,
    'server_seq': ++_seq,
    'server_received_at': DateTime.utc(2026, 3, 1, 12).toIso8601String(),
  };

  @override
  Future<List<Map<String, Object?>>> pull(
    String table, {
    required int afterSeq,
    required int limit,
  }) async {
    _call();
    final newer =
        (rows[table]?.values ?? const <Map<String, Object?>>[])
            .where((r) => (r['server_seq']! as int) > afterSeq)
            .toList()
          ..sort(
            (a, b) =>
                (a['server_seq']! as int).compareTo(b['server_seq']! as int),
          );
    return [for (final r in newer.take(limit)) Map.of(r)];
  }
}
