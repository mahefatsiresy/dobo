import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// One pond preparation step done (SPEC F10, DOMAIN §Pond preparation).
/// Dose in grams; entered in kg.
@DataClassName('PrepStepRow')
class PrepSteps extends Table with SyncedRow, EventRow {
  TextColumn get pondId => text()();
  TextColumn get step => textEnum<PrepStep>()();
  TextColumn get product => textEnum<PrepProduct>().nullable()();
  IntColumn get doseG => integer().nullable()();
}
