@Tags(['server'])
library;

import 'package:dobo/db/ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'server_env.dart';

/// The reset-secret edge function: an admin sets a new password or PIN
/// (SPEC F14, F16).
void main() {
  late final ServerEnv env;
  late final FoundedAssociation a;
  late final FoundedAssociation other;
  final stamp = DateTime.now().microsecondsSinceEpoch;

  Future<(int, Object?)> call(
    SupabaseClient client,
    String fn,
    Map<String, Object?> body,
  ) async {
    try {
      final res = await client.functions.invoke(fn, body: body);
      return (res.status, res.data);
    } on FunctionException catch (e) {
      return (e.status, e.details);
    }
  }

  /// Creates an account in [f]'s association; returns its member id.
  Future<String> account(
    FoundedAssociation f, {
    required String role,
    required String login,
    required String secret,
  }) async {
    final memberId = newId();
    final (status, answer) = await call(f.client, 'create-account', {
      'memberId': memberId,
      'name': login,
      'role': role,
      'login': login,
      'secret': secret,
      'isAdmin': false,
      'isSales': false,
      'locale': 'fr',
      'deviceId': f.deviceId,
    });
    expect(status, 200, reason: '$answer');
    return memberId;
  }

  Future<(int, Object?)> reset(
    SupabaseClient client,
    String memberId,
    String secret,
  ) => call(client, 'reset-secret', {'memberId': memberId, 'secret': secret});

  setUpAll(() async {
    env = ServerEnv.fromEnvironment();
    a = await env.foundAssociation();
    other = await env.foundAssociation();
  });

  test("an admin resets a worker's PIN: the new one signs in, the old one "
      'no longer does', () async {
    final w = await account(
      a,
      role: 'worker',
      login: 'w$stamp',
      secret: '123456',
    );
    final (status, answer) = await reset(a.client, w, '654321');
    expect(status, 200, reason: '$answer');
    await env.signedInClient('w$stamp@ouvriers.dobo.invalid', '654321');
    await expectLater(
      env.signedInClient('w$stamp@ouvriers.dobo.invalid', '123456'),
      throwsA(isA<AuthException>()),
    );
  });

  test('a 5-digit PIN is refused with bad_secret', () async {
    final w = await account(
      a,
      role: 'worker',
      login: 'p$stamp',
      secret: '123456',
    );
    final (status, answer) = await reset(a.client, w, '12345');
    expect(status, 400);
    expect((answer as Map)['error'], 'bad_secret');
  });

  test("a member's password under 8 characters is refused with bad_secret", () async {
    final m = await account(
      a,
      role: 'member',
      login: 'm$stamp@test.mg',
      secret: 'motdepasse1',
    );
    final (status, answer) = await reset(a.client, m, 'court');
    expect(status, 400);
    expect((answer as Map)['error'], 'bad_secret');
  });

  test('a call with no session gets not_admin, whatever the gateway lets '
      'through', () async {
    final nobody = SupabaseClient(
      env.url,
      env.publishableKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    for (final fn in ['reset-secret', 'create-account']) {
      final (status, answer) = await call(nobody, fn, {
        'memberId': a.memberId,
        'secret': 'pirate123',
      });
      expect((status, (answer as Map)['error']), (403, 'not_admin'), reason: fn);
    }
    await env.signedInClient(a.email, a.password);
  });

  test('a plain member gets not_admin', () async {
    final m = await account(
      a,
      role: 'member',
      login: 'plain$stamp@test.mg',
      secret: 'motdepasse1',
    );
    final plain = await env.signedInClient('plain$stamp@test.mg', 'motdepasse1');
    final (status, answer) = await reset(plain, m, 'nouveaumotdepasse');
    expect(status, 403);
    expect((answer as Map)['error'], 'not_admin');
  });

  test('an admin of another association gets no_member and the password is '
      'unchanged', () async {
    final (status, answer) = await reset(
      other.client,
      a.memberId,
      'pirate123',
    );
    expect(status, 404);
    expect((answer as Map)['error'], 'no_member');
    await env.signedInClient(a.email, a.password);
  });
}
