import 'package:drift/drift.dart';

import '../db/database.dart';

/// Reference rows are edited in place (last write wins); events are only
/// ever inserted (SPEC §7).
enum RowKind { reference, event }

/// One table the phone syncs.
class SyncTable {
  const SyncTable(this.info, this.kind);

  final TableInfo<Table, Object?> info;
  final RowKind kind;

  String get name => info.actualTableName;
}

/// Every synced table, in push order: who and where first, then what
/// happened. The server keeps no foreign keys, so the order only makes a
/// half-finished sync tidier, never possible or not.
List<SyncTable> syncTables(AppDatabase db) => [
  SyncTable(db.groups, RowKind.reference),
  SyncTable(db.members, RowKind.reference),
  SyncTable(db.sites, RowKind.reference),
  SyncTable(db.people, RowKind.reference),
  SyncTable(db.ponds, RowKind.reference),
  SyncTable(db.batches, RowKind.reference),
  SyncTable(db.visits, RowKind.reference),
  SyncTable(db.settingOverrides, RowKind.reference),
  SyncTable(db.stockings, RowKind.event),
  SyncTable(db.transfers, RowKind.event),
  SyncTable(db.dailyLogs, RowKind.event),
  SyncTable(db.waterReadings, RowKind.event),
  SyncTable(db.samples, RowKind.event),
  SyncTable(db.observations, RowKind.event),
  SyncTable(db.healthEvents, RowKind.event),
  SyncTable(db.treatments, RowKind.event),
  SyncTable(db.visitReports, RowKind.event),
  SyncTable(db.photos, RowKind.event),
];
