import 'dart:io';

import 'package:dobo/db/ids.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The local Supabase stack the `server` tests run against. Set by
/// tool/server_test.sh from `supabase status`.
class ServerEnv {
  ServerEnv.fromEnvironment()
    : url = _required('SUPABASE_URL'),
      anonKey = _required('SUPABASE_ANON_KEY'),
      serviceRoleKey = _required('SUPABASE_SERVICE_ROLE_KEY'),
      dbUrl = _required('SUPABASE_DB_URL'),
      foundingCode = _required('FOUNDING_CODE');

  final String url;
  final String anonKey;
  final String serviceRoleKey;

  /// Postgres itself, for checks PostgREST can't make (psql).
  final String dbUrl;

  /// The local founding code, from `supabase/functions/.env`.
  final String foundingCode;

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

  /// A client with the service role: the admin API, no row-level security.
  SupabaseClient serviceClient() => SupabaseClient(
    url,
    serviceRoleKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  /// A founded association, without the edge function: a confirmed login
  /// from the admin API, then `found_association` with a code hash never
  /// used, so fixtures never spend the local founding code.
  Future<FoundedAssociation> foundAssociation({
    String? email,
    String password = 'motdepasse1',
    String name = 'Famille',
  }) async {
    final service = serviceClient();
    final login = email ?? 'founder${newId()}@test.mg';
    final created = await service.auth.admin.createUser(
      AdminUserAttributes(email: login, password: password, emailConfirm: true),
    );
    final f = FoundedAssociation(
      associationId: newId(),
      groupId: newId(),
      siteId: newId(),
      memberId: newId(),
      deviceId: newId(),
      email: login,
      password: password,
    );
    await service.rpc<void>(
      'found_association',
      params: {
        'p_code_hash': 'fixture-${newId()}',
        'p_user_id': created.user!.id,
        'p_email': login,
        'p_association_id': f.associationId,
        'p_association_name': name,
        'p_group_id': f.groupId,
        'p_group_name': 'Branche 1',
        'p_site_id': f.siteId,
        'p_site_name': 'Ambohidratrimo',
        'p_location_note': null,
        'p_member_id': f.memberId,
        'p_person_id': f.personId,
        'p_member_name': 'Founder',
        'p_locale': 'fr',
        'p_device_id': f.deviceId,
      },
    );
    f.client = await signedInClient(login, password);
    return f;
  }

  /// Makes the local founding code usable again (it is spent once used).
  Future<void> unspendFoundingCode() async {
    final out = await Process.run('psql', [
      dbUrl,
      '-c',
      "delete from founding_codes_spent where code_hash = "
          "encode(sha256(convert_to('$foundingCode', 'UTF8')), 'hex')",
    ]);
    if (out.exitCode != 0) throw StateError('${out.stderr}');
  }
}

/// What [ServerEnv.foundAssociation] made, and the founder signed in.
class FoundedAssociation {
  FoundedAssociation({
    required this.associationId,
    required this.groupId,
    required this.siteId,
    required this.memberId,
    required this.deviceId,
    required this.email,
    required this.password,
  });

  final String associationId;
  final String groupId;
  final String siteId;
  final String memberId;
  final String deviceId;
  final String email;
  final String password;
  String get personId => accountPersonId(memberId);
  late final SupabaseClient client;
}
