import 'package:drift/drift.dart';

import '../../domain/farm_facts.dart';
import '../../domain/occupancy.dart';
import '../database.dart';
import '../events.dart';
import '../sync_columns.dart';
import 'batch_repository.dart';
import 'watch_tables.dart';

/// Every current stocking, move, sample, daily log and harvest (SPEC §4: what all
/// derived numbers are computed from).
Future<FarmFacts> currentFacts(AppDatabase db) async => FarmFacts(
  stockings: [
    for (final s in await currentEvents(db, db.stockings).get())
      StockingFact(
        batchId: s.batchId,
        pondId: s.pondId,
        count: s.count,
        avgWeightG: s.avgWeightMg / 1000,
        date: s.recordedAt,
      ),
  ],
  transfers: [
    for (final t in await currentEvents(db, db.transfers).get())
      TransferFact(
        batchId: t.batchId,
        fromPondId: t.fromPondId,
        toPondId: t.toPondId,
        count: t.count,
        avgWeightG: t.avgWeightMg == null ? null : t.avgWeightMg! / 1000,
        date: t.recordedAt,
      ),
  ],
  samples: [
    for (final s in await currentEvents(db, db.samples).get())
      SampleFact(
        batchId: s.batchId,
        pondId: s.pondId,
        avgWeightG: s.totalWeightG / s.fishCount,
        date: s.recordedAt,
      ),
  ],
  logs: [
    for (final l in await currentEvents(db, db.dailyLogs).get())
      LogFact(
        id: l.id,
        pondId: l.pondId,
        date: l.recordedAt,
        feedG: l.feedGivenG,
        deaths: l.deaths,
        signs: {...l.warningSigns, ...l.deathSigns},
        waterColour: l.waterColour,
        enteredBy: l.enteredBy,
        observedBy: l.observedBy,
        feedLotId: l.feedLotId,
      ),
  ],
  harvests: [
    for (final h in await currentEvents(db, db.harvests).get())
      HarvestFact(
        batchId: h.batchId,
        pondId: h.pondId,
        count: h.count,
        weightG: h.weightG,
        isFinal: h.isFinal,
        date: h.recordedAt,
      ),
  ],
);

/// [currentFacts] now and after every change to their tables.
Stream<FarmFacts> watchFarmFacts(AppDatabase db) =>
    watchTables(db, placementTables(db), () => currentFacts(db));

/// Current rows of an event table in a fixed order: recorded date, then
/// device creation time, then id, so same-day facts don't depend on
/// SQLite's row order.
SimpleSelectStatement<T, D> currentEvents<T extends HasResultSet, D>(
  AppDatabase db,
  ResultSetImplementation<T, D> table,
) {
  final info = table as TableInfo<Table, D>;
  final cols = info as SyncedRow;
  final event = info as EventRow;
  return db.select(table)
    ..where((_) => isCurrentEvent(info))
    ..orderBy([
      (_) => OrderingTerm.asc(event.recordedAt),
      (_) => OrderingTerm.asc(cols.createdAtDevice),
      (_) => OrderingTerm.asc(cols.id),
    ]);
}
