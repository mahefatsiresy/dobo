import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../database.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';

class CustomerInput {
  const CustomerInput({required this.name, required this.type, this.contact});

  final String name;
  final CustomerType type;
  final String? contact;
}

/// Who buys the fish (SPEC F12). Reference rows: last write wins.
class CustomerRepository {
  CustomerRepository(this.db, this.session);

  final AppDatabase db;
  final Session session;

  Future<String> create(CustomerInput input) async =>
      (await db
              .into(db.customers)
              .insertReturning(
                CustomersCompanion.insert(
                  associationId: session.associationId,
                  enteredBy: session.userId,
                  deviceId: session.deviceId,
                  name: input.name.trim(),
                  type: input.type,
                  contact: Value(_blank(input.contact)),
                ),
              ))
          .id;

  Future<void> update(String id, CustomerInput input) => _write(
    id,
    CustomersCompanion(
      name: Value(input.name.trim()),
      type: Value(input.type),
      contact: Value(_blank(input.contact)),
    ),
  );

  Future<void> archive(String id) =>
      _write(id, const CustomersCompanion(archived: Value(true)));

  /// Customers not archived, by name.
  Stream<List<Customer>> watchActive() =>
      (db.select(db.customers)
            ..where((c) => c.archived.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch();

  Future<void> _write(String id, CustomersCompanion fields) =>
      (db.update(db.customers)..where((c) => c.id.equals(id))).write(
        fields.copyWith(
          updatedAtDevice: Value(utcNow()),
          syncState: const Value(SyncState.pending),
        ),
      );

  String? _blank(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
}
