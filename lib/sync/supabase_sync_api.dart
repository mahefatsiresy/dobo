import 'package:supabase_flutter/supabase_flutter.dart';

import 'server_errors.dart';
import 'sync_api.dart';

/// [SyncApi] over Supabase: pushes through the `sync_push` function, pulls
/// with PostgREST under row-level security.
class SupabaseSyncApi implements SyncApi {
  SupabaseSyncApi(this.client);

  final SupabaseClient client;

  /// With no session every row would be refused as anonymous; say so once.
  void _requireSession() {
    if (client.auth.currentSession == null) throw SyncSignedOut();
  }

  @override
  Future<List<PushOutcome>> push(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    _requireSession();
    if (rows.isEmpty) return const [];
    final result = await guardServer(
      () => client.rpc<List<dynamic>>(
        'sync_push',
        params: {'p_table': table, 'p_rows': rows},
      ),
    );
    return [
      for (final r in result.cast<Map<String, dynamic>>())
        PushOutcome(
          id: r['id'] as String,
          serverSeq: r['server_seq'] as int?,
          serverReceivedAt: r['server_received_at'] == null
              ? null
              : DateTime.parse(r['server_received_at'] as String),
          errorCode: r['error_code'] as String?,
          errorMessage: r['error_message'] as String?,
        ),
    ];
  }

  @override
  Future<List<Map<String, Object?>>> pull(
    String table, {
    required int afterSeq,
    required int limit,
  }) async {
    _requireSession();
    return guardServer(
      () => client
          .from(table)
          .select()
          .gt('server_seq', afterSeq)
          .order('server_seq', ascending: true)
          .limit(limit),
    );
  }
}
