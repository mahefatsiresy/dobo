import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../database.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';
import 'facts_repository.dart';

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

  /// Customers not archived, those who bought most recently first (their
  /// latest current sale), then the rest by name: the sale form's picker.
  Stream<List<Customer>> watchByRecentSale() async* {
    yield await _byRecentSale();
    await for (final _ in db.tableUpdates(
      TableUpdateQuery.onAllTables([db.customers, db.sales]),
    )) {
      yield await _byRecentSale();
    }
  }

  Future<List<Customer>> _byRecentSale() async {
    final latest = <String, DateTime>{};
    for (final s in await currentEvents(db, db.sales).get()) {
      final at = latest[s.customerId];
      if (at == null || s.recordedAt.isAfter(at)) {
        latest[s.customerId] = s.recordedAt;
      }
    }
    final active = await (db.select(
      db.customers,
    )..where((c) => c.archived.equals(false))).get();
    int byName(Customer a, Customer b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return active..sort((a, b) {
      final (x, y) = (latest[a.id], latest[b.id]);
      if (x != null && y != null) return y.compareTo(x);
      if (x != null) return -1;
      if (y != null) return 1;
      return byName(a, b);
    });
  }

  Future<void> _write(String id, CustomersCompanion fields) =>
      (db.update(db.customers)..where((c) => c.id.equals(id))).write(
        fields.copyWith(
          updatedAtDevice: Value(utcNow()),
          syncState: const Value(SyncState.pending),
        ),
      );

  String? _blank(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
}
