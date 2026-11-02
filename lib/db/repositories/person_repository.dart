import 'package:drift/drift.dart';

import '../database.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';

class PersonRepository {
  PersonRepository(this.db, this.session);

  final AppDatabase db;
  final Session session;

  /// Active people first, then by name.
  Stream<List<Person>> watchAll() =>
      (db.select(db.people)..orderBy([
            (p) => OrderingTerm.desc(p.active),
            (p) => OrderingTerm.asc(p.name.lower()),
          ]))
          .watch();

  Future<String> create({required String name, String? phone, String? note}) {
    final id = newId();
    return db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            id: Value(id),
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            name: name,
            phone: Value(phone),
            note: Value(note),
          ),
        )
        .then((_) => id);
  }

  Future<void> update(
    String id, {
    required String name,
    String? phone,
    String? note,
    required bool active,
  }) => (db.update(db.people)..where((p) => p.id.equals(id))).write(
    PeopleCompanion(
      name: Value(name),
      phone: Value(phone),
      note: Value(note),
      active: Value(active),
      updatedAtDevice: Value(utcNow()),
      syncState: const Value(SyncState.pending),
    ),
  );

  /// Gives every account without a person its own, with the id
  /// [accountPersonId] makes, so two admin phones doing this offline make
  /// one row. Only admins may write people (RLS), so only admin phones call
  /// this. Returns how many accounts it linked.
  Future<int> ensureAccountPeople() => db.transaction(() async {
    final unlinked = await (db.select(
      db.members,
    )..where((m) => m.personId.isNull())).get();
    for (final m in unlinked) {
      final personId = accountPersonId(m.id);
      await db
          .into(db.people)
          .insert(
            PeopleCompanion.insert(
              id: Value(personId),
              associationId: session.associationId,
              enteredBy: session.userId,
              deviceId: session.deviceId,
              name: m.name,
            ),
            // Already pulled from another admin's phone: keep that one.
            mode: InsertMode.insertOrIgnore,
          );
      await (db.update(db.members)..where((r) => r.id.equals(m.id))).write(
        MembersCompanion(
          personId: Value(personId),
          deviceId: Value(session.deviceId),
          updatedAtDevice: Value(utcNow()),
          syncState: const Value(SyncState.pending),
        ),
      );
    }
    return unlinked.length;
  });
}
