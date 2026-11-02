import 'package:dobo/db/database.dart';
import 'package:dobo/db/ids.dart';
import 'package:dobo/db/repositories/member_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sync/fake_auth_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeAuthGateway auth;
  late MemberRepository members;
  late GroupRepository groups;
  const session = Session(
    associationId: 'a1',
    userId: 'm1',
    deviceId: 'd1',
    siteId: 's1',
    isAdmin: true,
    isLinked: true,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    auth = FakeAuthGateway(member: remoteMember(id: 'm1', isAdmin: true));
    members = MemberRepository(db, session, auth);
    groups = GroupRepository(db, session);
  });
  tearDown(() => db.close());

  Future<void> member(String id, String name, {String? groupId}) => db
      .into(db.members)
      .insert(
        MembersCompanion.insert(
          id: Value(id),
          associationId: 'a1',
          enteredBy: 'm1',
          deviceId: 'd1',
          name: name,
          groupId: Value(groupId),
          role: MemberRole.member,
          locale: 'fr',
          syncState: const Value(SyncState.synced),
        ),
      );

  test('members are listed by group, then name', () async {
    final rabe = await groups.create('Rabe');
    final ando = await groups.create('Ando');
    await member('m2', 'Zo', groupId: ando);
    await member('m3', 'Bako', groupId: rabe);
    await member('m4', 'Aina', groupId: ando);
    expect((await members.watchAll().first).map((m) => m.name), [
      'Aina',
      'Zo',
      'Bako',
    ]);
  });

  test('editing a member offline marks the row pending', () async {
    await member('m2', 'Soa');
    await members.update(
      'm2',
      name: 'Soa R.',
      role: MemberRole.member,
      isAdmin: false,
      isSales: true,
      active: true,
      locale: 'fr',
    );
    final m = await db.select(db.members).getSingle();
    expect(
      (m.name, m.isSales, m.syncState),
      ('Soa R.', true, SyncState.pending),
    );
  });

  test('renaming a member renames the linked person', () async {
    await member('m2', 'Hery');
    await db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            id: const Value('p2'),
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            name: 'Hery',
            syncState: const Value(SyncState.synced),
          ),
        );
    await (db.update(db.members)..where((m) => m.id.equals('m2'))).write(
      const MembersCompanion(personId: Value('p2')),
    );
    await members.update(
      'm2',
      name: 'Hery Rabe',
      role: MemberRole.member,
      isAdmin: false,
      isSales: false,
      active: true,
      locale: 'fr',
    );
    final p = await (db.select(
      db.people,
    )..where((p) => p.id.equals('p2'))).getSingle();
    expect((p.name, p.syncState), ('Hery Rabe', SyncState.pending));
  });

  test('a member changes their own language', () async {
    await member('m1', 'Admin');
    await members.setOwnLocale('mg');
    final m = await db.select(db.members).getSingle();
    expect((m.locale, m.syncState), ('mg', SyncState.pending));
  });

  test('creating an account stores the server\'s row as synced', () async {
    final id = await members.create(
      NewAccount(
        memberId: 'w1',
        name: 'Rakoto',
        role: MemberRole.worker,
        login: 'rakoto',
        secret: '123456',
        locale: 'mg',
        deviceId: 'd1',
      ),
    );
    expect(id, 'w1');
    final m = await db.select(db.members).getSingle();
    expect((m.name, m.role), ('Rakoto', MemberRole.worker));
    // The admin's phone gives the new account its person straight away.
    expect(m.personId, accountPersonId('w1'));
    final p = await db.select(db.people).getSingle();
    expect((p.id, p.name), (accountPersonId('w1'), 'Rakoto'));
  });

  test('groups are created and renamed offline', () async {
    final id = await groups.create('Rabe');
    await groups.rename(id, 'Rabe-Ando');
    final g = await db.select(db.groups).getSingle();
    expect((g.name, g.syncState), ('Rabe-Ando', SyncState.pending));
  });
}
