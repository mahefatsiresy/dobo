import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// Feed received (SPEC F11). A delivery is a feed lot: its id is the lot id
/// daily logs draw from. [manufacturedOn] is a farm day.
@DataClassName('FeedDelivery')
class FeedDeliveries extends Table with SyncedRow, EventRow {
  TextColumn get siteId => text()();
  TextColumn get phase => textEnum<Phase>()();
  RealColumn get pelletMm => real().nullable()();
  RealColumn get proteinPct => real().nullable()();
  IntColumn get weightG => integer()();
  DateTimeColumn get manufacturedOn => dateTime()();
  TextColumn get supplier => text().nullable()();

  /// A short mark on the sacks, to tell lots apart.
  TextColumn get label => text().nullable()();
}
