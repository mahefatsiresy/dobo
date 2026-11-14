@Tags(['server'])
library;

import 'package:dobo/db/ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'server_env.dart';

/// The found-association edge function with the real local founding code
/// (SPEC F16). Each test makes the code usable again first.
void main() {
  late final ServerEnv env;

  setUpAll(() => env = ServerEnv.fromEnvironment());
  setUp(() => env.unspendFoundingCode());

  Map<String, Object?> founding({String? email, String? code}) {
    final memberId = newId();
    return {
      'code': code ?? env.foundingCode,
      'email': email ?? 'founder${newId()}@test.mg',
      'password': 'motdepasse1',
      'founderName': 'Rabe',
      'associationName': 'Famille Rabe',
      'groupName': 'Branche 1',
      'siteName': 'Ambohidratrimo',
      'locationNote': 'Près du lac',
      'associationId': newId(),
      'groupId': newId(),
      'siteId': newId(),
      'memberId': memberId,
      'personId': accountPersonId(memberId),
      'deviceId': newId(),
    };
  }

  Future<(int, Object?)> found(Map<String, Object?> body) async {
    try {
      final res = await env.anonClient().functions.invoke(
        'found-association',
        body: body,
      );
      return (res.status, res.data);
    } on FunctionException catch (e) {
      return (e.status, e.details);
    }
  }

  Future<int> associationsWithIds(List<Object?> ids) async {
    final rows = await env
        .serviceClient()
        .from('associations')
        .select('id')
        .inFilter('id', ids);
    return rows.length;
  }

  test('founding with the code creates an admin who signs in and sees the '
      'site', () async {
    final body = founding();
    final (status, answer) = await found(body);
    expect(status, 200, reason: '$answer');
    expect((answer as Map)['memberId'], body['memberId']);

    final founder = await env.signedInClient(
      body['email']! as String,
      'motdepasse1',
    );
    final me = await founder
        .from('members')
        .select()
        .eq('id', body['memberId']!)
        .single();
    expect(
      (me['is_admin'], me['active'], me['person_id'], me['locale']),
      (true, true, body['personId'], 'fr'),
    );
    final sites = await founder.from('sites').select();
    expect(sites.single['name'], 'Ambohidratrimo');
    final people = await founder.from('people').select();
    expect(people.single['id'], body['personId']);
  });

  test('the same code again is refused with bad_code and leaves no login', () async {
    expect((await found(founding())).$1, 200);
    final second = founding();
    final (status, answer) = await found(second);
    expect(status, 403);
    expect((answer as Map)['error'], 'bad_code');
    await expectLater(
      env.signedInClient(second['email']! as String, 'motdepasse1'),
      throwsA(isA<AuthException>()),
    );
  });

  test('a wrong code is refused with bad_code', () async {
    final (status, answer) = await found(founding(code: 'pas-le-bon'));
    expect(status, 403);
    expect((answer as Map)['error'], 'bad_code');
  });

  test('an email already in use is refused with login_taken', () async {
    final email = 'dup${newId()}@test.mg';
    expect((await found(founding(email: email))).$1, 200);
    await env.unspendFoundingCode();
    final (status, answer) = await found(founding(email: email));
    expect(status, 409);
    expect((answer as Map)['error'], 'login_taken');
  });

  test('two foundings at once with one code make one association', () async {
    final a = founding();
    final b = founding();
    final results = await Future.wait([found(a), found(b)]);
    final statuses = results.map((r) => r.$1).toList()..sort();
    expect(statuses, [200, 403]);
    expect(
      await associationsWithIds([a['associationId'], b['associationId']]),
      1,
    );
    // The loser's login was removed with its founding.
    final loser = results[0].$1 == 403 ? a : b;
    await expectLater(
      env.signedInClient(loser['email']! as String, 'motdepasse1'),
      throwsA(isA<AuthException>()),
    );
  });

  test('founding works with a publishable key, which is not a JWT', () async {
    final client = SupabaseClient(
      env.url,
      env.publishableKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    late int status;
    try {
      status = (await client.functions.invoke(
        'found-association',
        body: founding(),
      )).status;
    } on FunctionException catch (e) {
      status = e.status;
    }
    expect(status, 200);
  });

  test('OPTIONS answers 204 with the CORS headers', () async {
    final res = await http.Client().send(
      http.Request(
        'OPTIONS',
        Uri.parse('${env.url}/functions/v1/found-association'),
      ),
    );
    expect(res.statusCode, 204);
    expect(res.headers['access-control-allow-origin'], '*');
    expect(
      res.headers['access-control-allow-headers'],
      contains('authorization'),
    );
  });
}
