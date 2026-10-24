import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// Workers and others, with or without an account (SPEC §4).
@DataClassName('Person')
class People extends Table with SyncedRow, ReferenceRow {
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}
