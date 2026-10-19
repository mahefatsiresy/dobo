import 'package:drift/drift.dart';

import '../sync_columns.dart';

class Sites extends Table with SyncedRow, ReferenceRow {
  TextColumn get name => text()();
  TextColumn get locationNote => text().nullable()();
}
