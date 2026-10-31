/// The server, as the sync engine sees it (SPEC §7). Implemented over
/// Supabase in the app and in memory in tests.
abstract interface class SyncApi {
  /// Sends [rows] of [table]; one outcome per row, in any order.
  Future<List<PushOutcome>> push(String table, List<Map<String, Object?>> rows);

  /// Rows of [table] with `server_seq` above [afterSeq], oldest first.
  Future<List<Map<String, Object?>>> pull(
    String table, {
    required int afterSeq,
    required int limit,
  });
}

/// What the server did with one pushed row.
class PushOutcome {
  const PushOutcome({
    required this.id,
    this.serverSeq,
    this.serverReceivedAt,
    this.errorCode,
    this.errorMessage,
  });

  final String id;
  final int? serverSeq;
  final DateTime? serverReceivedAt;

  /// Postgres SQLSTATE (`42501`: the role may not write this) or a code
  /// raised by the server (`last_admin`). Null when accepted.
  final String? errorCode;
  final String? errorMessage;

  bool get accepted => errorCode == null;
}

/// The server couldn't be reached. Nothing is lost: try again later.
class SyncOffline implements Exception {}

/// The account's session has ended; someone must sign in again.
class SyncSignedOut implements Exception {}
