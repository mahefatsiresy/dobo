import 'package:drift/drift.dart';

import 'ids.dart';
import 'sync_state.dart';

/// Columns every synced row carries (SPEC §4).
mixin SyncedRow on Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get associationId => text()();
  TextColumn get enteredBy => text()();
  TextColumn get observedBy => text().nullable()();
  DateTimeColumn get createdAtDevice => dateTime().clientDefault(utcNow)();
  TextColumn get deviceId => text()();
  DateTimeColumn get serverReceivedAt => dateTime().nullable()();
  IntColumn get serverSeq => integer().nullable()();
  TextColumn get syncState =>
      textEnum<SyncState>().withDefault(Constant(SyncState.pending.name))();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Editable reference entities (ponds, batches, people…): last-write-wins.
/// Apply after [SyncedRow].
mixin ReferenceRow on Table {
  DateTimeColumn get updatedAtDevice => dateTime().clientDefault(utcNow)();
}

/// Append-only event records: corrections supersede, deletions are tombstones.
/// Apply after [SyncedRow].
mixin EventRow on Table {
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get supersedesId => text().nullable()();
  BoolColumn get isTombstone => boolean().withDefault(const Constant(false))();
}
