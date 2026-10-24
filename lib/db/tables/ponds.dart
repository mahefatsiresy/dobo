import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// No unique constraint on `code`: two phones may create the same code
/// offline, and sync must never refuse a row.
@DataClassName('Pond')
class Ponds extends Table with SyncedRow, ReferenceRow {
  TextColumn get siteId => text()();
  TextColumn get code => text()();
  TextColumn get colour => textEnum<PondColour>()();
  TextColumn get structure => textEnum<StructureType>().withDefault(
    Constant(StructureType.earth.name),
  )();
  TextColumn get role => textEnum<PondRole>()();
  TextColumn get waterSupply => textEnum<WaterSupply>().nullable()();
  RealColumn get lengthM => real().nullable()();
  RealColumn get widthM => real().nullable()();
  RealColumn get surfaceM2Override => real().nullable()();
  RealColumn get depthInletM => real().nullable()();
  RealColumn get depthOutletM => real().nullable()();
  TextColumn get status =>
      textEnum<PondStatus>().withDefault(Constant(PondStatus.empty.name))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}
