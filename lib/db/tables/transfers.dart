import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// Fish of one batch moved from one pond to another (sorting or quarantine
/// release).
@DataClassName('Transfer')
class Transfers extends Table with SyncedRow, EventRow {
  TextColumn get batchId => text()();
  TextColumn get fromPondId => text()();
  TextColumn get toPondId => text()();
  IntColumn get count => integer()();
  IntColumn get avgWeightMg => integer().nullable()();
}
