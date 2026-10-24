import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// Temperature, pH, oxygen and colour of a pond at a time.
@DataClassName('WaterReading')
class WaterReadings extends Table with SyncedRow, EventRow {
  /// The visit it was entered during, if any (SPEC F5).
  TextColumn get visitId => text().nullable()();
  TextColumn get pondId => text()();
  RealColumn get temperatureC => real().nullable()();
  RealColumn get ph => real().nullable()();
  RealColumn get oxygenMgL => real().nullable()();
  TextColumn get colour => textEnum<WaterColour>().nullable()();
  IntColumn get renewedPct => integer().nullable()();
}
