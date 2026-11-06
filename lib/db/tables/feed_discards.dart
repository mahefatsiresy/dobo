import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// Feed thrown away from a lot (DOMAIN §Feed stock).
@DataClassName('FeedDiscard')
class FeedDiscards extends Table with SyncedRow, EventRow {
  TextColumn get lotId => text()();
  IntColumn get weightG => integer()();
  TextColumn get reason => textEnum<DiscardReason>()();
}
