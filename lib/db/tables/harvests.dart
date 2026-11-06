import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// Fish taken out of a pond for sale (SPEC F12). A final harvest ends the
/// batch's part in that pond.
@DataClassName('Harvest')
class Harvests extends Table with SyncedRow, EventRow {
  TextColumn get batchId => text()();
  TextColumn get pondId => text()();
  IntColumn get count => integer()();
  IntColumn get weightG => integer()();
  BoolColumn get isFinal => boolean()();
}
