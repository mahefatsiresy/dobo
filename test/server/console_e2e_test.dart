@Tags(['server'])
library;

import 'package:dobo/console/data/console_api.dart';
import 'package:dobo/console/data/supabase_console_api.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/ids.dart';
import 'package:dobo/db/repositories/account_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:dobo/sync/supabase_auth_gateway.dart';
import 'package:dobo/sync/supabase_sync_api.dart';
import 'package:dobo/sync/sync_engine.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'server_env.dart';

/// M9 walk-through (SPEC F16): the association is founded in the console,
/// which creates a worker and resets the PIN; the worker's phone signs in
/// with the new PIN and syncs what the console wrote.
void main() {
  test('founded on the web, a worker created and reset there signs in on a '
      'phone and gets the site, groups and people', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final env = ServerEnv.fromEnvironment();
    await env.unspendFoundingCode();
    final stamp = DateTime.now().microsecondsSinceEpoch;

    // 1. The founder, in the browser.
    final console = SupabaseConsoleApi(env.anonClient(), newId());
    final founding = Founding.planned(
      code: env.foundingCode,
      email: 'web$stamp@test.mg',
      password: 'motdepasse1',
      founderName: 'Soa',
      associationName: 'Famille Web $stamp',
      groupName: 'Branche 1',
      siteName: 'Ambohidratrimo',
      locationNote: 'Près du lac',
    );
    await console.foundAssociation(founding);
    expect((await console.me()).isAdmin, true);

    // 2. A worker and a second branch.
    final workerId = newId();
    await console.saveGroup(
      GroupRow(id: newId(), name: 'Branche 2'),
      isNew: true,
    );
    await console.createAccount(
      NewAccount(
        memberId: workerId,
        name: 'Rakoto',
        role: MemberRole.worker,
        login: 'rakoto$stamp',
        secret: '123456',
        locale: 'mg',
        deviceId: '',
        groupId: founding.groupId,
      ),
    );

    // 3. The PIN is reset.
    await console.resetSecret(workerId, '654321');

    // 4. The worker's phone.
    final phone = AppDatabase(NativeDatabase.memory());
    addTearDown(phone.close);
    final client = env.anonClient();
    final gateway = SupabaseAuthGateway(client);
    final accounts = AccountRepository(phone, SetupRepository(phone), gateway);
    await expectLater(
      accounts.signIn(login: 'rakoto$stamp', secret: '123456', worker: true),
      throwsA(isA<AuthFailed>()),
    );
    await accounts.signIn(
      login: 'rakoto$stamp',
      secret: '654321',
      worker: true,
    );

    // 5. One sync later.
    await SyncEngine(phone, SupabaseSyncApi(client)).run();
    final site = await phone.select(phone.sites).getSingle();
    expect((site.id, site.name), (founding.siteId, 'Ambohidratrimo'));
    final groups = await phone.select(phone.groups).get();
    expect(
      groups.map((g) => g.name).toSet(),
      {'Branche 1', 'Branche 2'},
    );
    final people = await phone.select(phone.people).get();
    expect(
      people.map((p) => p.id).toSet(),
      {founding.personId, accountPersonId(workerId)},
    );
    final me = await (phone.select(
      phone.members,
    )..where((m) => m.id.equals(workerId))).getSingle();
    expect(
      (me.role, me.personId, me.groupId, me.locale),
      (MemberRole.worker, accountPersonId(workerId), founding.groupId, 'mg'),
    );
  });
}
