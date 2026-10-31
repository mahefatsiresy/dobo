import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// The local Supabase stack the `server` tests run against. Set by
/// tool/server_test.sh from `supabase status`.
class ServerEnv {
  ServerEnv.fromEnvironment()
    : url = _required('SUPABASE_URL'),
      anonKey = _required('SUPABASE_ANON_KEY'),
      serviceRoleKey = _required('SUPABASE_SERVICE_ROLE_KEY');

  final String url;
  final String anonKey;
  final String serviceRoleKey;

  static String _required(String name) {
    final value = Platform.environment[name];
    if (value == null || value.isEmpty) {
      throw StateError('$name is not set: run tool/server_test.sh');
    }
    return value;
  }

  /// A client with nobody signed in.
  SupabaseClient anonClient() => SupabaseClient(
    url,
    anonKey,
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );

  /// A client signed in as [email].
  Future<SupabaseClient> signedInClient(String email, String password) async {
    final client = anonClient();
    await client.auth.signInWithPassword(email: email, password: password);
    return client;
  }

  /// A new account, signed in (email confirmation is off locally).
  Future<SupabaseClient> signedUpClient(String email, String password) async {
    final client = anonClient();
    await client.auth.signUp(email: email, password: password);
    return client;
  }
}
