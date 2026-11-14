@Tags(['server'])
library;

import 'package:dobo/db/ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'server_env.dart';

/// Calls the create-account function; returns its status and body.
Future<(int, Object?)> createAccount(
  SupabaseClient client,
  Map<String, Object?> body,
) async {
  try {
    final res = await client.functions.invoke('create-account', body: body);
    return (res.status, res.data);
  } on FunctionException catch (e) {
    return (e.status, e.details);
  }
}

void main() {
  late final ServerEnv env;
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final deviceId = newId();
  late SupabaseClient founder;

  Map<String, Object?> worker(String login, String pin) => {
    'memberId': newId(),
    'name': 'Rakoto',
    'role': 'worker',
    'login': login,
    'secret': pin,
    'isAdmin': false,
    'isSales': false,
    'locale': 'mg',
    'deviceId': deviceId,
  };

  setUpAll(() async {
    env = ServerEnv.fromEnvironment();
    founder = (await env.foundAssociation(name: 'Famille $stamp')).client;
  });

  test('an admin creates a worker who can then sign in with the PIN', () async {
    final body = worker('rakoto$stamp', '123456');
    final (status, row) = await createAccount(founder, body);
    expect(status, 200);
    expect((row as Map)['role'], 'worker');
    expect(row['id'], body['memberId']);

    final rakoto = await env.signedInClient(
      'rakoto$stamp@ouvriers.dobo.invalid',
      '123456',
    );
    expect(await rakoto.from('ponds').select(), isEmpty);
    final me = await rakoto
        .from('members')
        .select()
        .eq('id', body['memberId']!);
    expect(me.single['locale'], 'mg');
  });

  test('a login already in use is refused', () async {
    await createAccount(founder, worker('dup$stamp', '123456'));
    final (status, body) = await createAccount(
      founder,
      worker('dup$stamp', '654321'),
    );
    expect(status, 409);
    expect((body as Map)['error'], 'login_taken');
  });

  test('a PIN that is not 6 digits is refused', () async {
    final (status, body) = await createAccount(
      founder,
      worker('pin$stamp', '12ab56'),
    );
    expect(status, 400);
    expect((body as Map)['error'], 'bad_secret');
  });

  test('a worker cannot create accounts', () async {
    await createAccount(founder, worker('w$stamp', '123456'));
    final w = await env.signedInClient(
      'w$stamp@ouvriers.dobo.invalid',
      '123456',
    );
    final (status, body) = await createAccount(w, worker('x$stamp', '123456'));
    expect(status, 403);
    expect((body as Map)['error'], 'not_admin');
  });
}
