import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/account_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:dobo/sync/sync_api.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sync/fake_auth_gateway.dart';

void main() {
  late AppDatabase db;
  late SetupRepository setup;
  late FakeAuthGateway auth;
  late AccountRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    setup = SetupRepository(db);
    auth = FakeAuthGateway();
    repo = AccountRepository(db, setup, auth);
  });
  tearDown(() => db.close());

  Future<Map<String, String>> meta() async => {
    for (final r in await db.select(db.localMeta).get()) r.key: r.value,
  };

  Future<void> logs(int n, String associationId) => db.batch((b) {
    for (var i = 0; i < n; i++) {
      b.insert(
        db.dailyLogs,
        DailyLogsCompanion.insert(
          associationId: associationId,
          enteredBy: 'm0',
          deviceId: 'd0',
          recordedAt: DateTime.utc(2026, 3, 1, 9),
          pondId: 'p1',
          feedGivenG: 600,
        ),
      );
    }
  });

  test('Review Focus 4: signing in to another association on a phone '
      'holding unsent records is refused, nothing changes', () async {
    final local = await setup.completeSetup(siteName: 'Ambohidratrimo');
    await logs(2, local.associationId);
    await setup.clearUser();
    final before = await meta();
    auth.member = remoteMember(associationId: 'other');

    await expectLater(
      repo.signIn(login: 'soa@b.mg', secret: 'motdepasse', worker: false),
      throwsA(
        isA<AuthFailed>().having((e) => e.code, 'code', 'other_association'),
      ),
    );
    expect(await meta(), before);
    expect(await db.select(db.dailyLogs).get(), hasLength(2));
    expect(auth.signedIn, false);
  });

  test('a worker signs in on an empty phone with username and PIN', () async {
    auth.member = remoteMember(id: 'w1', role: MemberRole.worker, locale: 'mg');
    await repo.signIn(login: ' Rakoto ', secret: '123456', worker: true);
    expect(auth.lastEmail, workerEmail('rakoto'));
    final s = (await setup.currentSession())!;
    expect((s.userId, s.associationId, s.siteId), ('w1', 'a1', 's1'));
    expect(s.isWorker, true);
    expect((await meta())['linked'], '1');
  });

  test('signing in again on the same association keeps every record', () async {
    final local = await setup.completeSetup(siteName: 'Ambohidratrimo');
    await logs(3, local.associationId);
    await repo.signOut();
    auth.member = remoteMember(
      id: 'm2',
      associationId: local.associationId,
      siteId: local.siteId,
    );
    await repo.signIn(login: 'soa@a.mg', secret: 'motdepasse', worker: false);
    expect((await setup.currentSession())!.userId, 'm2');
    expect(await db.select(db.dailyLogs).get(), hasLength(3));
  });

  test('a different member signing in puts refused rows back in the queue',
      () async {
    final local = await setup.completeSetup(siteName: 'Ambohidratrimo');
    await db
        .into(db.waterReadings)
        .insert(
          WaterReadingsCompanion.insert(
            associationId: local.associationId,
            enteredBy: local.userId,
            deviceId: 'd0',
            recordedAt: DateTime.utc(2026, 3, 1, 9),
            pondId: 'p1',
            syncState: const Value(SyncState.rejected),
            syncError: const Value('42501: refused'),
          ),
        );
    await repo.signOut();
    auth.member = remoteMember(id: 'm2', associationId: local.associationId);
    await repo.signIn(login: 'soa@a.mg', secret: 'motdepasse', worker: false);
    final r = await db.select(db.waterReadings).getSingle();
    expect(r.syncState, SyncState.pending);
  });

  test('creating the association from an M3 phone keeps its ids', () async {
    final local = await setup.completeSetup(siteName: 'Ambohidratrimo');
    await repo.createAssociation(
      associationName: 'Famille Rabe',
      groupName: 'Branche 1',
      memberName: 'Soa',
      email: 'soa@a.mg',
      password: 'motdepasse',
      siteName: 'ignored',
    );
    final sent = auth.createdAssociations.single;
    expect(
      (sent['associationId'], sent['memberId']),
      (local.associationId, local.userId),
    );
    expect(sent['deviceId'], await db.deviceId());
    expect(await db.select(db.sites).get(), hasLength(1));
    final s = (await setup.currentSession())!;
    expect((s.userId, s.siteId, s.isAdmin), (local.userId, local.siteId, true));
    expect((await meta())['linked'], '1');
  });

  test('creating the association on an empty phone sets the phone up', () async {
    await repo.createAssociation(
      associationName: 'Famille Rabe',
      groupName: 'Branche 1',
      memberName: 'Soa',
      email: 'soa@a.mg',
      password: 'motdepasse',
      siteName: 'Ambohidratrimo',
      locationNote: 'RN4',
    );
    final sent = auth.createdAssociations.single;
    final s = (await setup.currentSession())!;
    expect((s.associationId, s.userId), (sent['associationId'], sent['memberId']));
    final site = await db.select(db.sites).getSingle();
    expect((site.id, site.name, site.locationNote), (s.siteId, 'Ambohidratrimo', 'RN4'));
  });

  test('an account already made by a failed attempt is signed into', () async {
    final retry = FakeAuthGateway(existingEmails: {'soa@a.mg'});
    await AccountRepository(db, setup, retry).createAssociation(
      associationName: 'Famille Rabe',
      groupName: 'Branche 1',
      memberName: 'Soa',
      email: 'soa@a.mg',
      password: 'motdepasse',
      siteName: 'Ambohidratrimo',
    );
    expect(retry.signedIn, true);
    expect(retry.createdAssociations, hasLength(1));
  });

  test('no network: nothing is written', () async {
    auth.offline = true;
    await expectLater(
      repo.signIn(login: 'soa@a.mg', secret: 'motdepasse', worker: false),
      throwsA(isA<SyncOffline>()),
    );
    expect(await meta(), isEmpty);
  });

  test('pendingCount counts unsent rows of every table', () async {
    final local = await setup.completeSetup(siteName: 'Ambohidratrimo');
    await logs(2, local.associationId);
    expect(await repo.pendingCount(), 3); // the site and two logs
  });

  test('a signed-out phone with records cannot found a second association',
      () async {
    await setup.completeSetup(siteName: 'Ambohidratrimo');
    await repo.signOut();
    final before = await meta();
    await expectLater(
      repo.createAssociation(
        associationName: 'Autre',
        groupName: 'Branche 1',
        memberName: 'Soa',
        email: 'soa@x.mg',
        password: 'motdepasse',
        siteName: 'X',
      ),
      throwsA(
        isA<AuthFailed>().having((e) => e.code, 'code', 'other_association'),
      ),
    );
    expect(await meta(), before);
    expect(auth.createdAssociations, isEmpty);
  });
}
