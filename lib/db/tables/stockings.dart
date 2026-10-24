import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// A batch put into a pond. Average weight in milligrams: whole grams are
/// too coarse at fingerling size.
@DataClassName('Stocking')
class Stockings extends Table with SyncedRow, EventRow {
  TextColumn get batchId => text()();
  TextColumn get pondId => text()();
  IntColumn get count => integer()();
  IntColumn get avgWeightMg => integer()();
  BoolColumn get acclimatised => boolean().nullable()();
}
