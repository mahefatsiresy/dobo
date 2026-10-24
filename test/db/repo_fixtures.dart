import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/native.dart';

/// An in-memory database that has been through first-launch setup.
Future<(AppDatabase, Session)> setUpFarm() async {
  final db = AppDatabase(NativeDatabase.memory());
  final session = await SetupRepository(db)
      .completeSetup(siteName: 'Ambohidratrimo');
  return (db, session);
}

PondInput pondInput(
  String code, {
  PondRole role = PondRole.growout,
  PondColour colour = PondColour.blue,
  StructureType structure = StructureType.earth,
  double? lengthM,
  double? widthM,
}) => PondInput(
  code: code,
  colour: colour,
  structure: structure,
  role: role,
  lengthM: lengthM,
  widthM: widthM,
);

StockInput stockInput(
  String code, {
  required String pondId,
  int count = 1000,
  int avgWeightMg = 12500,
  DateTime? date,
}) => StockInput(
  code: code,
  pondId: pondId,
  date: date ?? DateTime(2026, 3, 1),
  count: count,
  avgWeightMg: avgWeightMg,
);

TransferInput moveInput(
  String batchId, {
  required String from,
  required String to,
  required int count,
  DateTime? date,
  int? avgWeightMg,
}) => TransferInput(
  batchId: batchId,
  fromPondId: from,
  toPondId: to,
  date: date ?? DateTime(2026, 3, 10),
  count: count,
  avgWeightMg: avgWeightMg,
);
