import 'package:dobo/db/database.dart';
import 'package:dobo/db/ids.dart';
import 'package:dobo/db/repositories/person_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late PersonRepository people;
  late Session session;

  setUp(() async {
    final (d, s) = await setUpFarm();
    db = d;
    session = s;
    people = PersonRepository(db, s);
  });

  Future<void> member(String id, String name, {String? personId}) => db
      .into(db.members)
      .insert(
        MembersCompanion.insert(
          id: Value(id),
          associationId: session.associationId,
          enteredBy: session.userId,
          deviceId: 'other',
          name: name,
          personId: Value(personId),
          role: personId == null ? MemberRole.member : MemberRole.worker,
          locale: 'fr',
          syncState: const Value(SyncState.synced),
        ),
      );

  Future<Member> memberRow(String id) =>
      (db.select(db.members)..where((m) => m.id.equals(id))).getSingle();
  tearDown(() => db.close());

  test('inactive people sort after active ones, then by name', () async {
    final rakoto = await people.create(name: 'Rakoto');
    await people.create(name: 'Rabe');
    await people.create(name: 'Soa', phone: '034 00 000 00');
    await people.update(rakoto, name: 'Rakoto', active: false);
    final names = [for (final p in await people.watchAll().first) p.name];
    expect(names, ['Rabe', 'Soa', 'Rakoto']);
  });

  test('an update marks the row pending again', () async {
    final id = await people.create(name: 'Rakoto');
    await (db.update(db.people)..where((p) => p.id.equals(id))).write(
      const PeopleCompanion(syncState: Value(SyncState.synced)),
    );
    await people.update(id, name: 'Rakotobe', note: 'Gardien', active: true);
    final row = await (db.select(
      db.people,
    )..where((p) => p.id.equals(id))).getSingle();
    expect(
      (row.name, row.note, row.syncState),
      ('Rakotobe', 'Gardien', SyncState.pending),
    );
  });

  group('ensureAccountPeople', () {
    test('links unlinked members only', () async {
      await member('w1', 'Rakoto', personId: 'p9');
      await member('m2', 'Hery');
      expect(await people.ensureAccountPeople(), 1);

      expect((await memberRow('w1')).personId, 'p9');
      final hery = await memberRow('m2');
      expect(hery.personId, accountPersonId('m2'));
      expect(hery.syncState, SyncState.pending);
      final person = await (db.select(
        db.people,
      )..where((p) => p.id.equals(accountPersonId('m2')))).getSingle();
      expect((person.name, person.syncState), ('Hery', SyncState.pending));
    });

    test('twice writes nothing the second time', () async {
      await member('m2', 'Hery');
      await people.ensureAccountPeople();
      await db
          .update(db.people)
          .write(const PeopleCompanion(syncState: Value(SyncState.synced)));
      await db
          .update(db.members)
          .write(const MembersCompanion(syncState: Value(SyncState.synced)));
      expect(await people.ensureAccountPeople(), 0);
      final pending = await (db.select(
        db.people,
      )..where((p) => p.syncState.equalsValue(SyncState.pending))).get();
      expect(pending, isEmpty);
    });

    test('a person already pulled from another admin is reused', () async {
      await member('m2', 'Hery');
      await db
          .into(db.people)
          .insert(
            PeopleCompanion.insert(
              id: Value(accountPersonId('m2')),
              associationId: session.associationId,
              enteredBy: 'admin2',
              deviceId: 'other',
              name: 'Hery',
              syncState: const Value(SyncState.synced),
            ),
          );
      expect(await people.ensureAccountPeople(), 1);
      final rows = await db.select(db.people).get();
      expect(rows.where((p) => p.name == 'Hery'), hasLength(1));
      expect(rows.single.syncState, SyncState.synced);
      expect((await memberRow('m2')).personId, accountPersonId('m2'));
    });
  });
}
