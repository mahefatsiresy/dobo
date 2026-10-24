import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// A condition check (`ok` set) or a free observation, for a pond or the
/// site.
@DataClassName('Observation')
class Observations extends Table with SyncedRow, EventRow {
  /// The visit it was entered during, if any (SPEC F5).
  TextColumn get visitId => text().nullable()();
  TextColumn get siteId => text()();
  TextColumn get pondId => text().nullable()();
  TextColumn get category => textEnum<ObservationCategory>()();
  BoolColumn get ok => boolean().nullable()();
  TextColumn get note => text().nullable()();
}
