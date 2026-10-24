import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../converters.dart';
import '../sync_columns.dart';

/// One pond-day: feed, leftovers, deaths and signs (SPEC F3). Recorded at
/// the farm date's noon.
@DataClassName('DailyLog')
class DailyLogs extends Table with SyncedRow, EventRow {
  /// The visit it was entered during, if any (SPEC F5).
  TextColumn get visitId => text().nullable()();
  TextColumn get pondId => text()();
  IntColumn get feedGivenG => integer()();

  /// Feed lot drawn from (M7).
  TextColumn get feedLotId => text().nullable()();
  IntColumn get feedings => integer().nullable()();
  TextColumn get leftover => textEnum<Leftover>().nullable()();
  BoolColumn get ateFast => boolean().withDefault(const Constant(false))();
  IntColumn get deaths => integer().withDefault(const Constant(0))();
  TextColumn get deathSigns => text()
      .map(warningSignsConverter)
      .withDefault(const Constant(''))();
  TextColumn get warningSigns => text()
      .map(warningSignsConverter)
      .withDefault(const Constant(''))();
  TextColumn get waterColour => textEnum<WaterColour>().nullable()();
  TextColumn get note => text().nullable()();
}
