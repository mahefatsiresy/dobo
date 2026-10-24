import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// A treatment given on someone's advice; the app never suggests one.
@DataClassName('Treatment')
class Treatments extends Table with SyncedRow, EventRow {
  /// The visit it was entered during, if any (SPEC F5).
  TextColumn get visitId => text().nullable()();
  TextColumn get pondId => text()();
  TextColumn get batchId => text().nullable()();
  TextColumn get product => text()();
  TextColumn get dose => text()();
  TextColumn get advisedBy => text().nullable()();
}
