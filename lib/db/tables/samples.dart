import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// Fish of a batch weighed together in one pond (DOMAIN §Sampling).
@DataClassName('Sample')
class Samples extends Table with SyncedRow, EventRow {
  /// The visit it was entered during, if any (SPEC F5).
  TextColumn get visitId => text().nullable()();
  TextColumn get batchId => text()();
  TextColumn get pondId => text()();
  IntColumn get fishCount => integer()();
  IntColumn get totalWeightG => integer()();
}
