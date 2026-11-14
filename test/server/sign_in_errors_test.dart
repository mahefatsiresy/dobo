@Tags(['server'])
library;

import 'package:dobo/console/data/supabase_console_api.dart';
import 'package:dobo/db/ids.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:dobo/sync/supabase_auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import 'server_env.dart';

/// A refused password is a wrong login, not a lost connection: the phone
/// and the console must say "Identifiant ou mot de passe incorrect".
void main() {
  late final ServerEnv env;
  late final FoundedAssociation a;

  setUpAll(() async {
    env = ServerEnv.fromEnvironment();
    a = await env.foundAssociation();
  });

  test('the phone gateway: a wrong password is AuthFailed(invalid_credentials)', () async {
    await expectLater(
      SupabaseAuthGateway(env.anonClient()).signIn(
        email: a.email,
        password: 'pasbon1234',
      ),
      throwsA(
        isA<AuthFailed>().having((e) => e.code, 'code', 'invalid_credentials'),
      ),
    );
  });

  test('the console: a wrong password is AuthFailed(invalid_credentials)', () async {
    await expectLater(
      SupabaseConsoleApi(env.anonClient(), newId()).signIn(a.email, 'pasbon1234'),
      throwsA(
        isA<AuthFailed>().having((e) => e.code, 'code', 'invalid_credentials'),
      ),
    );
  });
}
