@Tags(['server'])
library;

import 'dart:io';

import 'package:dobo/console/data/console_api.dart';
import 'package:dobo/console/data/supabase_console_api.dart';
import 'package:dobo/db/ids.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:dobo/sync/supabase_sync_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'server_env.dart';

/// The console's data layer on the real local server (SPEC F16).
void main() {
  late final ServerEnv env;
  late final FoundedAssociation a;
  late final SupabaseConsoleApi console;
  final stamp = DateTime.now().microsecondsSinceEpoch;

  setUpAll(() async {
    env = ServerEnv.fromEnvironment();
    a = await env.foundAssociation(name: 'Famille $stamp');
    console = SupabaseConsoleApi(env.anonClient(), newId());
    await console.signIn(a.email, a.password);
  });

  Future<String> psql(String sql) async {
    final out = await Process.run('psql', [env.dbUrl, '-At', '-c', sql]);
    expect(out.exitCode, 0, reason: '${out.stderr}');
    return (out.stdout as String).trim();
  }

  test('me() returns the founder as an active admin with the association '
      'name', () async {
    final me = await console.me();
    expect(
      (me.memberId, me.associationId, me.associationName, me.isAdmin, me.active),
      (a.memberId, a.associationId, 'Famille $stamp', true, true),
    );
  });

  test('saveGroup(isNew) then groups() lists it, and a phone pull sees it '
      'with server_seq', () async {
    final id = newId();
    await console.saveGroup(GroupRow(id: id, name: 'Branche 2'), isNew: true);
    expect((await console.groups()).map((g) => g.name), contains('Branche 2'));
    final pulled = await SupabaseSyncApi(
      a.client,
    ).pull('groups', afterSeq: 0, limit: 100);
    final row = pulled.singleWhere((r) => r['id'] == id);
    expect(row['server_seq'], isNotNull);
    expect(row['entered_by'], a.memberId);
  });

  test('renaming a group keeps the old name in reference_history', () async {
    final id = newId();
    await console.saveGroup(GroupRow(id: id, name: 'Avant'), isNew: true);
    final g = (await console.groups()).singleWhere((g) => g.id == id);
    await console.saveGroup(g.copyWith(name: 'Après'));
    expect(
      (await console.groups()).singleWhere((g) => g.id == id).name,
      'Après',
    );
    expect(
      await psql(
        "select row ->> 'name' from reference_history "
        "where table_name = 'groups' and row_id = '$id'",
      ),
      'Avant',
    );
  });

  test("saveMember turning off the last admin's flag throws "
      "ConsoleWriteFailed('last_admin')", () async {
    final me = (await console.members()).singleWhere(
      (m) => m.id == a.memberId,
    );
    await expectLater(
      console.saveMember(me.copyWith(isAdmin: false)),
      throwsA(
        isA<ConsoleWriteFailed>().having((e) => e.code, 'code', 'last_admin'),
      ),
    );
    expect(
      (await console.members()).singleWhere((m) => m.id == a.memberId).isAdmin,
      true,
    );
  });

  test("createAccount pushes the account's person first", () async {
    final memberId = newId();
    await console.createAccount(
      NewAccount(
        memberId: memberId,
        name: 'Rakoto',
        role: MemberRole.worker,
        login: 'rk$stamp',
        secret: '123456',
        locale: 'mg',
        deviceId: newId(),
      ),
    );
    final person = (await console.people()).singleWhere(
      (p) => p.id == accountPersonId(memberId),
    );
    expect((person.name, person.active), ('Rakoto', true));
    final m = (await console.members()).singleWhere((m) => m.id == memberId);
    expect((m.personId, m.role, m.login), (person.id, MemberRole.worker, 'rk$stamp'));
  });

  test('renameAssociation changes associations.name', () async {
    await console.renameAssociation('Famille Rabe $stamp');
    expect((await console.me()).associationName, 'Famille Rabe $stamp');
  });

  test('resetSecret sets a new PIN', () async {
    final memberId = newId();
    await console.createAccount(
      NewAccount(
        memberId: memberId,
        name: 'Bema',
        role: MemberRole.worker,
        login: 'bm$stamp',
        secret: '123456',
        locale: 'mg',
        deviceId: newId(),
      ),
    );
    await console.resetSecret(memberId, '654321');
    await env.signedInClient('bm$stamp@ouvriers.dobo.invalid', '654321');
  });

  group('founding through the edge function', () {
    setUp(() => env.unspendFoundingCode());

    Founding planned(String email) => Founding.planned(
      code: env.foundingCode,
      email: email,
      password: 'motdepasse1',
      founderName: 'Rabe',
      associationName: 'Famille F$stamp',
      groupName: 'Branche 1',
      siteName: 'Ambohidratrimo',
      locationNote: null,
    );

    test('foundAssociation called twice with the same Founding succeeds both '
        'times and makes one association', () async {
      final f = planned('ff$stamp@test.mg');
      final first = SupabaseConsoleApi(env.anonClient(), newId());
      await first.foundAssociation(f);
      expect((await first.me()).associationId, f.associationId);

      // The answer was lost: the same form is sent again.
      final retry = SupabaseConsoleApi(env.anonClient(), newId());
      await retry.foundAssociation(f);
      expect((await retry.me()).associationId, f.associationId);
      expect(
        await psql(
          "select count(*) from associations where name = 'Famille F$stamp'",
        ),
        '1',
      );
    });

    test("foundAssociation with an email another association uses throws "
        "AuthFailed('login_taken') and ends signed out", () async {
      final api = SupabaseConsoleApi(env.anonClient(), newId());
      final f = Founding.planned(
        code: env.foundingCode,
        email: a.email,
        password: a.password,
        founderName: 'Intrus',
        associationName: 'Autre',
        groupName: 'Branche 1',
        siteName: 'Ailleurs',
        locationNote: null,
      );
      await expectLater(
        api.foundAssociation(f),
        throwsA(
          isA<AuthFailed>().having((e) => e.code, 'code', 'login_taken'),
        ),
      );
      expect(api.hasSession, false);
    });
  });
}
