import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/types.dart';
import 'auth_gateway.dart';
import 'server_errors.dart';

/// [AuthGateway] over Supabase Auth, the `create_association` function and
/// the `create-account` edge function.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this.client);

  final SupabaseClient client;

  @override
  bool get hasSession => client.auth.currentSession != null;

  @override
  Future<void> signIn({required String email, required String password}) =>
      _auth(
        () => client.auth.signInWithPassword(email: email, password: password),
      );

  @override
  Future<void> signUp({required String email, required String password}) =>
      _auth(() => client.auth.signUp(email: email, password: password));

  /// Wrong credentials and the like are [AuthFailed]; no network is still
  /// `SyncOffline`.
  Future<void> _auth(Future<AuthResponse> Function() call) async {
    try {
      await guardServer(call);
    } on AuthApiException catch (e) {
      throw AuthFailed(e.code ?? 'auth_failed');
    }
  }

  @override
  Future<void> signOut() async {
    // Local only: signing out must work offline.
    await client.auth.signOut(scope: SignOutScope.local);
  }

  @override
  Future<RemoteMember> myMember() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw const AuthFailed('no_member');
    final rows = await guardServer(
      () => client.from('members').select().eq('user_id', userId),
    );
    if (rows.isEmpty) throw const AuthFailed('no_member');
    final m = rows.single;
    final associationId = m['association_id'] as String;
    final association = await guardServer(
      () => client
          .from('associations')
          .select('name')
          .eq('id', associationId)
          .single(),
    );
    final sites = await guardServer(
      () => client
          .from('sites')
          .select('id')
          .eq('association_id', associationId)
          .order('created_at_device', ascending: true)
          .limit(1),
    );
    return RemoteMember(
      id: m['id'] as String,
      associationId: associationId,
      associationName: association['name'] as String,
      siteId: sites.isEmpty ? null : sites.single['id'] as String,
      name: m['name'] as String,
      role: MemberRole.values.byName(m['role'] as String),
      isAdmin: m['is_admin'] as bool,
      isSales: m['is_sales'] as bool,
      locale: m['locale'] as String,
    );
  }

  @override
  Future<void> createAssociation({
    required String associationId,
    required String associationName,
    required String groupId,
    required String groupName,
    required String memberId,
    required String memberName,
    required String locale,
    required String deviceId,
  }) async {
    try {
      await guardServer(
        () => client.rpc<void>(
          'create_association',
          params: {
            'p_association_id': associationId,
            'p_association_name': associationName,
            'p_group_id': groupId,
            'p_group_name': groupName,
            'p_member_id': memberId,
            'p_member_name': memberName,
            'p_locale': locale,
            'p_device_id': deviceId,
          },
        ),
      );
    } on PostgrestException catch (e) {
      throw AuthFailed(e.message);
    }
  }

  @override
  Future<Map<String, Object?>> createAccount(NewAccount account) async {
    try {
      final res = await guardServer(
        () => client.functions.invoke('create-account', body: account.toJson()),
      );
      return (res.data as Map).cast<String, Object?>();
    } on FunctionException catch (e) {
      final details = e.details;
      throw AuthFailed(
        details is Map && details['error'] is String
            ? details['error'] as String
            : 'status_${e.status}',
      );
    }
  }
}
