import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// An admin's override of one farming number for a site (SPEC F14). The id
/// is derived from site and key, so every phone edits the same row.
@DataClassName('SettingOverride')
class SettingOverrides extends Table with SyncedRow, ReferenceRow {
  TextColumn get siteId => text()();
  TextColumn get key => text()();

  /// Null: back to the DOMAIN value.
  RealColumn get value => real().nullable()();
}
