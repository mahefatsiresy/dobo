@Tags(['server'])
library;

import 'package:dobo/db/database.dart';
import 'package:dobo/db/ids.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:dobo/sync/supabase_auth_gateway.dart';
import 'package:dobo/sync/supabase_sync_api.dart';
import 'package:dobo/sync/sync_api.dart';
import 'package:dobo/sync/sync_engine.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'server_env.dart';

/// Two phones on the real local server: the founder (admin) and a worker.
void main() {
  late ServerEnv env;
  late AppDatabase founderPhone;
  late AppDatabase workerPhone;
  late SyncEngine founderSync;
  late SyncEngine workerSync;
  late String associationId;
  late String founderId;
  late String workerId;
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final founderDevice = newId();
  final workerDevice = newId();
  final siteId = newId();
  final pondId = newId();

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    env = ServerEnv.fromEnvironment();
    associationId = newId();
    founderId = newId();
    workerId = newId();

    final founderClient = env.anonClient();
    final founder = SupabaseAuthGateway(founderClient);
    await founder.signUp(email: 'f$stamp@test.mg', password: 'motdepasse1');
    await founder.createAssociation(
      associationId: associationId,
      associationName: 'Famille $stamp',
      groupId: newId(),
      groupName: 'Branche 1',
      memberId: founderId,
      memberName: 'Founder',
      locale: 'fr',
      deviceId: founderDevice,
    );
    await founder.createAccount(
      NewAccount(
        memberId: workerId,
        name: 'Rakoto',
        role: MemberRole.worker,
        login: 'r$stamp',
        secret: '123456',
        locale: 'mg',
        deviceId: founderDevice,
      ),
    );
    final me = await founder.myMember();
    expect(
      (me.id, me.isAdmin, me.associationName),
      (founderId, true, 'Famille $stamp'),
    );

    final workerClient = env.anonClient();
    final worker = SupabaseAuthGateway(workerClient);
    await worker.signIn(email: workerEmail('r$stamp'), password: '123456');
    final w = await worker.myMember();
    expect((w.id, w.role), (workerId, MemberRole.worker));

    founderPhone = AppDatabase(NativeDatabase.memory());
    workerPhone = AppDatabase(NativeDatabase.memory());
    founderSync = SyncEngine(founderPhone, SupabaseSyncApi(founderClient));
    workerSync = SyncEngine(workerPhone, SupabaseSyncApi(workerClient));
  });

  tearDownAll(() async {
    await founderPhone.close();
    await workerPhone.close();
  });

  Future<void> logs(AppDatabase phone, String by, String device, int n) =>
      phone.batch((b) {
        for (var i = 0; i < n; i++) {
          b.insert(
            phone.dailyLogs,
            DailyLogsCompanion.insert(
              associationId: associationId,
              enteredBy: by,
              deviceId: device,
              recordedAt: DateTime.utc(2026, 3, 1, 9),
              pondId: pondId,
              feedGivenG: 600,
            ),
          );
        }
      });

  test('the founder adds a pond, the worker logs it, the founder sees the '
      'log', () async {
    await founderPhone
        .into(founderPhone.sites)
        .insert(
          SitesCompanion.insert(
            id: Value(siteId),
            associationId: associationId,
            enteredBy: founderId,
            deviceId: founderDevice,
            name: 'Ambohidratrimo',
          ),
        );
    await founderPhone
        .into(founderPhone.ponds)
        .insert(
          PondsCompanion.insert(
            id: Value(pondId),
            associationId: associationId,
            enteredBy: founderId,
            deviceId: founderDevice,
            siteId: siteId,
            code: 'E1',
            colour: PondColour.blue,
            role: PondRole.growout,
          ),
        );
    final pushed = await founderSync.run();
    expect((pushed.pushed, pushed.rejected), (2, 0));

    await workerSync.run();
    final pond = await workerPhone.select(workerPhone.ponds).getSingle();
    expect((pond.code, pond.syncState), ('E1', SyncState.synced));
    expect(
      (await workerPhone.select(workerPhone.members).get()).map((m) => m.name),
      containsAll(['Founder', 'Rakoto']),
    );

    await logs(workerPhone, workerId, workerDevice, 1);
    await workerSync.run();
    await founderSync.run();
    final log = await founderPhone.select(founderPhone.dailyLogs).getSingle();
    expect((log.enteredBy, log.syncState), (workerId, SyncState.synced));
  });

  test('a worker\'s water reading is refused and kept', () async {
    await workerPhone
        .into(workerPhone.waterReadings)
        .insert(
          WaterReadingsCompanion.insert(
            associationId: associationId,
            enteredBy: workerId,
            deviceId: workerDevice,
            recordedAt: DateTime.utc(2026, 3, 1, 9),
            pondId: pondId,
            ph: const Value(7.2),
          ),
        );
    final report = await workerSync.run();
    expect(report.rejected, 1);
    final r = await workerPhone.select(workerPhone.waterReadings).getSingle();
    expect(r.syncState, SyncState.rejected);
    expect(r.syncError, startsWith('42501'));
  });

  test('Review Focus 3: two phones pushing at once, each then has every '
      'row', () async {
    await logs(founderPhone, founderId, founderDevice, 100);
    await logs(workerPhone, workerId, workerDevice, 100);
    await Future.wait([founderSync.run(), workerSync.run()]);
    await Future.wait([founderSync.run(), workerSync.run()]);

    for (final phone in [founderPhone, workerPhone]) {
      final all = await phone.select(phone.dailyLogs).get();
      expect(all, hasLength(201));
      expect(all.every((l) => l.syncState == SyncState.synced), true);
    }
  });

  test('a client nobody is signed in on is told so, not refused row by '
      'row', () async {
    final api = SupabaseSyncApi(env.anonClient());
    await expectLater(
      api.push('daily_logs', const []),
      throwsA(isA<SyncSignedOut>()),
    );
  });
}
