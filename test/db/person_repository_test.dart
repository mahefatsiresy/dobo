import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/person_repository.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late PersonRepository people;

  setUp(() async {
    final (d, s) = await setUpFarm();
    db = d;
    people = PersonRepository(db, s);
  });
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
}
