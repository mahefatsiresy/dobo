import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// A family branch; every member belongs to one (SPEC §3).
@DataClassName('Group')
class Groups extends Table with SyncedRow, ReferenceRow {
  TextColumn get name => text()();
}
