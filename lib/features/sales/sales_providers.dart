import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/database_provider.dart';
import '../../db/repositories/harvest_repository.dart';
import '../../db/repositories/providers.dart';

/// A batch's harvests, newest first, with their sales.
final batchHarvestsProvider =
    StreamProvider.family<List<HarvestWithSales>, String>(
      (ref, batchId) =>
          ref.watch(harvestRepositoryProvider).watchForBatch(batchId),
    );

/// Every harvest, newest first, with its sales.
final allHarvestsProvider = StreamProvider<List<HarvestWithSales>>(
  (ref) => ref.watch(harvestRepositoryProvider).watchAll(),
);

/// Customers to pick from.
final activeCustomersProvider = StreamProvider<List<Customer>>(
  (ref) => ref.watch(customerRepositoryProvider).watchActive(),
);

/// Every customer by id, archived ones included: past sales name them.
final customersByIdProvider = StreamProvider<Map<String, Customer>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.customers)
      .watch()
      .map((all) => {for (final c in all) c.id: c});
});
