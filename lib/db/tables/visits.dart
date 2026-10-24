import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// A member's trip to the site; groups the checks done that day (SPEC F5).
@DataClassName('Visit')
class Visits extends Table with SyncedRow, ReferenceRow {
  TextColumn get siteId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get summary => text().nullable()();
}
