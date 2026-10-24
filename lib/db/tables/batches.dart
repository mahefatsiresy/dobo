import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// A batch's identity. Its stocking date, count and weight come from its
/// current `Stocking` event, so correcting the stocking corrects the batch.
@DataClassName('Batch')
class Batches extends Table with SyncedRow, ReferenceRow {
  TextColumn get siteId => text()();
  TextColumn get code => text()();
  TextColumn get strain => text().nullable()();
  TextColumn get hatchery => text().nullable()();
  TextColumn get certificateNo => text().nullable()();
  BoolColumn get monosex => boolean().nullable()();
  DateTimeColumn get plannedHarvestOn => dateTime().nullable()();
  TextColumn get status => textEnum<BatchStatus>()();
}
