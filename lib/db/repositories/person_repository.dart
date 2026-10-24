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
}
