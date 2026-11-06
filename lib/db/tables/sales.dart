import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// Fish from a harvest going to a customer (SPEC F12). No price in v1
/// (CLAUDE.md §6); a price column can be added later.
@DataClassName('Sale')
class Sales extends Table with SyncedRow, EventRow {
  TextColumn get harvestId => text()();

  /// The harvest's batch, kept here for traceability queries.
  TextColumn get batchId => text()();
  TextColumn get customerId => text()();
  IntColumn get weightG => integer()();
  TextColumn get form => textEnum<ProductForm>()();
  TextColumn get deliveryNote => text().nullable()();
}
