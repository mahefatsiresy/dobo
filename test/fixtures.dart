import 'package:dobo/db/database.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/domain/stock.dart';
import 'package:dobo/domain/types.dart';

final _t = DateTime.utc(2026, 3, 1);

/// A pond row as the database would return it.
Pond pondRow(
  String id, {
  String? code,
  double? lengthM,
  double? widthM,
  StructureType structure = StructureType.earth,
  PondRole role = PondRole.growout,
  PondStatus status = PondStatus.ready,
}) => Pond(
  id: id,
  associationId: 'a1',
  enteredBy: 'u1',
  createdAtDevice: _t,
  deviceId: 'd1',
  syncState: SyncState.pending,
  updatedAtDevice: _t,
  siteId: 's1',
  code: code ?? id,
  colour: PondColour.blue,
  structure: structure,
  role: role,
  lengthM: lengthM,
  widthM: widthM,
  status: status,
  archived: false,
);

/// A batch row as the database would return it.
Batch batchRow(String id, {String? code}) => Batch(
  id: id,
  associationId: 'a1',
  enteredBy: 'u1',
  createdAtDevice: _t,
  deviceId: 'd1',
  syncState: SyncState.pending,
  updatedAtDevice: _t,
  siteId: 's1',
  code: code ?? id,
  status: BatchStatus.active,
);

Placement placementOf(
  String batchId,
  String pondId,
  int count,
  double? g, {
  bool inconsistent = false,
}) => Placement(
  batchId: batchId,
  pondId: pondId,
  live: LiveCount(count, inconsistent: inconsistent),
  avgWeightG: g,
);
