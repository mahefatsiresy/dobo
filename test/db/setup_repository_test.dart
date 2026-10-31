import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SetupRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SetupRepository(db);
  });
  tearDown(() => db.close());

  test('no session before setup', () async {
    expect(await repo.currentSession(), isNull);
  });

  test('setup creates the site and a session that persists', () async {
    final s = await repo.completeSetup(
      siteName: 'Ambohidratrimo',
      locationNote: 'Route RN4',
    );
    expect(
      await repo.currentSession(),
      isA<Session>()
          .having((x) => x.siteId, 'siteId', s.siteId)
          .having((x) => x.userId, 'userId', s.userId)
          .having((x) => x.associationId, 'associationId', s.associationId),
    );
    expect(s.deviceId, await db.deviceId());
    final site = await db.select(db.sites).getSingle();
    expect(
      (site.id, site.name, site.locationNote, site.enteredBy),
      (s.siteId, 'Ambohidratrimo', 'Route RN4', s.userId),
    );
    expect(site.associationId, s.associationId);
  });

  test('setup runs only once', () async {
    await repo.completeSetup(siteName: 'Ambohidratrimo');
    await expectLater(repo.completeSetup(siteName: 'X'), throwsStateError);
    expect(await db.select(db.sites).get(), hasLength(1));
  });

  group('watchSession', () {
    test('is null before setup', () async {
      expect(await repo.watchSession().first, isNull);
    });

    test('an M3 phone with no role recorded is a member and admin', () async {
      for (final (k, v) in [
        ('association_id', 'a1'),
        ('user_id', 'm1'),
        ('site_id', 's1'),
      ]) {
        await db
            .into(db.localMeta)
            .insert(LocalMetaCompanion.insert(key: k, value: v));
      }
      final s = (await repo.watchSession().first)!;
      expect((s.role, s.isAdmin, s.isSales), (MemberRole.member, true, false));
    });

    test('takes the role written at sign-in', () async {
      await repo.writeSignIn(
        associationId: 'a1',
        memberId: 'm3',
        siteId: 's1',
        role: MemberRole.worker,
        isAdmin: false,
        isSales: false,
      );
      final s = (await repo.watchSession().first)!;
      expect((s.userId, s.role, s.isWorker), ('m3', MemberRole.worker, true));
      expect(s.isAdmin, false);
    });

    test('the member row overrides what sign-in wrote, and re-emits', () async {
      await repo.writeSignIn(
        associationId: 'a1',
        memberId: 'm2',
        siteId: 's1',
        role: MemberRole.member,
        isAdmin: true,
        isSales: false,
      );
      final seen = <Session?>[];
      final sub = repo.watchSession().listen(seen.add);
      await pumpEventQueue();
      await db
          .into(db.members)
          .insert(
            MembersCompanion.insert(
              id: const Value('m2'),
              associationId: 'a1',
              enteredBy: 'm1',
              deviceId: 'd1',
              name: 'Soa',
              role: MemberRole.member,
              isSales: const Value(true),
              locale: 'fr',
              syncState: const Value(SyncState.synced),
            ),
          );
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, hasLength(2));
      expect((seen.last!.isAdmin, seen.last!.isSales), (false, true));
    });

    test('clearUser ends the session and keeps everything else', () async {
      final before = await repo.completeSetup(siteName: 'Ambohidratrimo');
      final deviceId = await db.deviceId();
      await repo.clearUser();
      expect(await repo.watchSession().first, isNull);
      final meta = {
        for (final r in await db.select(db.localMeta).get()) r.key: r.value,
      };
      expect(meta['association_id'], before.associationId);
      expect(meta['site_id'], before.siteId);
      expect(meta['device_id'], deviceId);
      expect(meta.containsKey('user_id'), false);
      expect(await db.select(db.sites).get(), hasLength(1));
    });

    test('completeSetup can reuse given ids and record a role', () async {
      const ids = Session(
        associationId: 'a9',
        userId: 'm9',
        deviceId: 'ignored',
        siteId: 's9',
      );
      final s = await repo.completeSetup(
        siteName: 'Ambohidratrimo',
        ids: ids,
        role: MemberRole.worker,
        isAdmin: false,
      );
      expect((s.associationId, s.userId, s.siteId), ('a9', 'm9', 's9'));
      expect(s.deviceId, await db.deviceId());
      final w = (await repo.watchSession().first)!;
      expect((w.role, w.isAdmin), (MemberRole.worker, false));
    });

    test('does not re-emit when an unrelated key changes', () async {
      await repo.completeSetup(siteName: 'Ambohidratrimo');
      final seen = <Session?>[];
      final sub = repo.watchSession().listen(seen.add);
      await pumpEventQueue();
      await db
          .into(db.localMeta)
          .insert(
            LocalMetaCompanion.insert(key: 'pull_cursor:ponds', value: '9'),
          );
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, hasLength(1));
    });

    test('an own member row not accepted by the server does not decide the '
        'role', () async {
      await repo.writeSignIn(
        associationId: 'a1',
        memberId: 'm1',
        siteId: 's1',
        role: MemberRole.member,
        isAdmin: true,
        isSales: false,
      );
      await db
          .into(db.members)
          .insert(
            MembersCompanion.insert(
              id: const Value('m1'),
              associationId: 'a1',
              enteredBy: 'm1',
              deviceId: 'd1',
              name: 'Soa',
              role: MemberRole.worker,
              locale: 'fr',
              syncState: const Value(SyncState.rejected),
            ),
          );
      final s = (await repo.watchSession().first)!;
      expect((s.role, s.isAdmin), (MemberRole.member, true));
    });
  });
}
