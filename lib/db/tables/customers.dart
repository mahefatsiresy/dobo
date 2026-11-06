import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// Who buys the fish (SPEC §4).
@DataClassName('Customer')
class Customers extends Table with SyncedRow, ReferenceRow {
  TextColumn get name => text()();
  TextColumn get type => textEnum<CustomerType>()();
  TextColumn get contact => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}
