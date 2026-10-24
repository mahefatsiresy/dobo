import 'package:drift/drift.dart';

import '../converters.dart';
import '../sync_columns.dart';

/// Signs seen, what was suspected and what was done (SPEC F9). Never a
/// diagnosis.
@DataClassName('HealthEvent')
class HealthEvents extends Table with SyncedRow, EventRow {
  /// The visit it was entered during, if any (SPEC F5).
  TextColumn get visitId => text().nullable()();
  TextColumn get pondId => text()();
  TextColumn get signs => text()
      .map(warningSignsConverter)
      .withDefault(const Constant(''))();
  TextColumn get suspectedIssue => text().nullable()();
  TextColumn get actions => text().map(healthActionsConverter)();
}
