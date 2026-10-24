// Drift's own Batch (bulk writes) clashes with the batch row class.
import 'package:drift/drift.dart' hide Batch;

import '../../domain/dates.dart';
import '../../domain/occupancy.dart';
import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_columns.dart';
import '../sync_state.dart';
import 'errors.dart';

/// A new batch and its first stocking (SPEC F2).
class StockInput {
  const StockInput({
    required this.code,
    this.strain,
    this.hatchery,
    this.certificateNo,
    this.monosex,
    this.plannedHarvestOn,
    required this.pondId,
    required this.date,
    required this.count,
    required this.avgWeightMg,
    this.acclimatised,
  });

  final String code;
  final String? strain;
  final String? hatchery;
  final String? certificateNo;
  final bool? monosex;

  /// Date only.
  final DateTime? plannedHarvestOn;
  final String pondId;

  /// Date only.
  final DateTime date;
  final int count;
  final int avgWeightMg;
  final bool? acclimatised;
}

/// A batch's identity fields.
class BatchInput {
  const BatchInput({
    required this.code,
    this.strain,
    this.hatchery,
    this.certificateNo,
    this.monosex,
    this.plannedHarvestOn,
  });

  final String code;
  final String? strain;
  final String? hatchery;
  final String? certificateNo;
  final bool? monosex;

  /// Date only.
  final DateTime? plannedHarvestOn;
}

/// The new values of a stocking being corrected.
class StockingCorrection {
  const StockingCorrection({
    required this.pondId,
    required this.date,
    required this.count,
    required this.avgWeightMg,
    this.acclimatised,
  });

  final String pondId;

  /// Date only.
  final DateTime date;
  final int count;
  final int avgWeightMg;
  final bool? acclimatised;
}

/// Fish of a batch moved between two ponds.
class TransferInput {
  const TransferInput({
    required this.batchId,
    required this.fromPondId,
    required this.toPondId,
    required this.date,
    required this.count,
    this.avgWeightMg,
  });

  final String batchId;
  final String fromPondId;
  final String toPondId;

  /// Date only.
  final DateTime date;
  final int count;
  final int? avgWeightMg;
}

class BatchSummary {
  const BatchSummary({
    required this.batch,
    required this.firstStocking,
    required this.liveCount,
  });

  final Batch batch;

  /// The earliest current stocking: the batch's stocking date, initial count
  /// and weight. Null when it was deleted.
  final Stocking? firstStocking;

  /// Estimated fish alive over all ponds.
  final int liveCount;
}

sealed class BatchEvent {
  const BatchEvent();

  DateTime get recordedAt;
}

final class StockingEvent extends BatchEvent {
  const StockingEvent(this.stocking);

  final Stocking stocking;

  @override
  DateTime get recordedAt => stocking.recordedAt;
}

final class TransferEvent extends BatchEvent {
  const TransferEvent(this.transfer);

  final Transfer transfer;

  @override
  DateTime get recordedAt => transfer.recordedAt;
}

class BatchRepository {
  BatchRepository(this.db, this.session);

  final AppDatabase db;
  final Session session;

  Stream<List<BatchSummary>> watchAll() =>
      _watch({db.batches, ...placementTables(db)}, () async {
        final stockings = await _currentStockings();
        final live = <String, int>{};
        for (final p in await _placements()) {
          live.update(
            p.batchId,
            (n) => n + p.live.count,
            ifAbsent: () => p.live.count,
          );
        }
        final batches =
            await (db.select(db.batches)
                  ..where((b) => b.siteId.equals(session.siteId))
                  ..orderBy([(b) => OrderingTerm.desc(b.code)]))
                .get();
        return [
          for (final b in batches)
            BatchSummary(
              batch: b,
              firstStocking: stockings
                  .where((s) => s.batchId == b.id)
                  .fold<Stocking?>(
                    null,
                    (first, s) =>
                        first == null || s.recordedAt.isBefore(first.recordedAt)
                        ? s
                        : first,
                  ),
              liveCount: live[b.id] ?? 0,
            ),
        ];
      });

  Stream<List<Placement>> watchPlacements() =>
      _watch(placementTables(db), _placements);

  /// Current stockings and moves of [batchId], newest first.
  Stream<List<BatchEvent>> watchHistory(String batchId) =>
      _watch({db.stockings, db.transfers}, () async {
        final events = <BatchEvent>[
          for (final s in await _currentStockings())
            if (s.batchId == batchId) StockingEvent(s),
          for (final t in await _currentTransfers())
            if (t.batchId == batchId) TransferEvent(t),
        ];
        // Stable sort keeps a same-day stocking below its moves.
        return events.reversed.toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      });

  Future<String> stockBatch(StockInput input) async {
    _checkPositive(input.count, input.avgWeightMg);
    return db.transaction(() async {
      await _checkCode(input.code);
      final pond = await _pond(input.pondId);
      final batchId = newId();
      await db
          .into(db.batches)
          .insert(
            BatchesCompanion.insert(
              id: Value(batchId),
              associationId: session.associationId,
              enteredBy: session.userId,
              deviceId: session.deviceId,
              siteId: session.siteId,
              code: input.code.trim(),
              strain: Value(input.strain),
              hatchery: Value(input.hatchery),
              certificateNo: Value(input.certificateNo),
              monosex: Value(input.monosex),
              plannedHarvestOn: Value(_date(input.plannedHarvestOn)),
              status: pond.role == PondRole.quarantine
                  ? BatchStatus.quarantine
                  : BatchStatus.active,
            ),
          );
      await db
          .into(db.stockings)
          .insert(
            _stocking(
              batchId: batchId,
              pondId: input.pondId,
              date: input.date,
              count: input.count,
              avgWeightMg: input.avgWeightMg,
              acclimatised: input.acclimatised,
            ),
          );
      await _markStocked(pond);
      return batchId;
    });
  }

  Future<void> updateBatch(String id, BatchInput input) =>
      db.transaction(() async {
        await _checkCode(input.code, exceptId: id);
        await (db.update(db.batches)..where((b) => b.id.equals(id))).write(
          BatchesCompanion(
            code: Value(input.code.trim()),
            strain: Value(input.strain),
            hatchery: Value(input.hatchery),
            certificateNo: Value(input.certificateNo),
            monosex: Value(input.monosex),
            plannedHarvestOn: Value(_date(input.plannedHarvestOn)),
            updatedAtDevice: Value(utcNow()),
            syncState: const Value(SyncState.pending),
          ),
        );
      });

  /// `L<yy>-<nn>`: one more than the highest number used in [today]'s year.
  String suggestBatchCode(List<Batch> batches, DateTime today) {
    final yy = (today.year % 100).toString().padLeft(2, '0');
    final pattern = RegExp('^L$yy-(\\d+)\$', caseSensitive: false);
    var highest = 0;
    for (final b in batches) {
      final n = int.tryParse(pattern.firstMatch(b.code.trim())?.group(1) ?? '');
      if (n != null && n > highest) highest = n;
    }
    return 'L$yy-${(highest + 1).toString().padLeft(2, '0')}';
  }

  Future<String> transfer(TransferInput input) async {
    _checkMove(input);
    return db.transaction(() async {
      final from = await _pond(input.fromPondId);
      if (from.status == PondStatus.isolated) {
        throw PondIsolatedException(from.id);
      }
      final to = await _pond(input.toPondId);
      final id = newId();
      await db.into(db.transfers).insert(_transfer(input, id: id));

      await _markStocked(to);
      final leftInSource = (await _placements())
          .where((p) => p.pondId == from.id)
          .fold(0, (n, p) => n + p.live.count);
      if (leftInSource == 0) await _setPondStatus(from.id, PondStatus.empty);

      final batch = await (db.select(
        db.batches,
      )..where((b) => b.id.equals(input.batchId))).getSingle();
      if (batch.status == BatchStatus.quarantine &&
          from.role == PondRole.quarantine &&
          to.role != PondRole.quarantine) {
        await (db.update(
          db.batches,
        )..where((b) => b.id.equals(batch.id))).write(
          BatchesCompanion(
            status: const Value(BatchStatus.active),
            updatedAtDevice: Value(utcNow()),
            syncState: const Value(SyncState.pending),
          ),
        );
      }
      return id;
    });
  }

  /// Statuses are left as they are; the member fixes them by hand.
  Future<String> correctStocking(String id, StockingCorrection c) async {
    _checkPositive(c.count, c.avgWeightMg);
    final old = await (db.select(
      db.stockings,
    )..where((s) => s.id.equals(id))).getSingle();
    return db.supersede(
      db.stockings,
      id,
      _stocking(
        batchId: old.batchId,
        pondId: c.pondId,
        date: c.date,
        count: c.count,
        avgWeightMg: c.avgWeightMg,
        acclimatised: c.acclimatised,
      ),
    );
  }

  Future<String> correctTransfer(String id, TransferInput input) async {
    _checkMove(input);
    return db.supersede(db.transfers, id, _transfer(input, id: newId()));
  }

  Future<void> deleteStocking(String id) =>
      db.tombstone(db.stockings, id, session);

  Future<void> deleteTransfer(String id) =>
      db.tombstone(db.transfers, id, session);

  StockingsCompanion _stocking({
    required String batchId,
    required String pondId,
    required DateTime date,
    required int count,
    required int avgWeightMg,
    bool? acclimatised,
  }) => StockingsCompanion.insert(
    associationId: session.associationId,
    enteredBy: session.userId,
    deviceId: session.deviceId,
    recordedAt: farmDateToUtc(date),
    batchId: batchId,
    pondId: pondId,
    count: count,
    avgWeightMg: avgWeightMg,
    acclimatised: Value(acclimatised),
  );

  TransfersCompanion _transfer(TransferInput input, {required String id}) =>
      TransfersCompanion.insert(
        id: Value(id),
        associationId: session.associationId,
        enteredBy: session.userId,
        deviceId: session.deviceId,
        recordedAt: farmDateToUtc(input.date),
        batchId: input.batchId,
        fromPondId: input.fromPondId,
        toPondId: input.toPondId,
        count: input.count,
        avgWeightMg: Value(input.avgWeightMg),
      );

  Future<List<Stocking>> _currentStockings() => _currentStockingsIn(db);

  Future<List<Transfer>> _currentTransfers() => _currentTransfersIn(db);

  Future<List<Placement>> _placements() => currentPlacements(db);

  Future<Pond> _pond(String id) =>
      (db.select(db.ponds)..where((p) => p.id.equals(id))).getSingle();

  /// Fish arrived in [pond]. Isolation is only lifted by a health event
  /// (SPEC F9), never by fish coming in.
  Future<void> _markStocked(Pond pond) async {
    if (pond.status != PondStatus.isolated) {
      await _setPondStatus(pond.id, PondStatus.stocked);
    }
  }

  Future<void> _setPondStatus(String id, PondStatus status) =>
      (db.update(db.ponds)..where((p) => p.id.equals(id))).write(
        PondsCompanion(
          status: Value(status),
          updatedAtDevice: Value(utcNow()),
          syncState: const Value(SyncState.pending),
        ),
      );

  Future<void> _checkCode(String code, {String? exceptId}) async {
    final wanted = normaliseCode(code);
    final clash =
        (await (db.select(
          db.batches,
        )..where((b) => b.siteId.equals(session.siteId))).get()).any(
          (b) => b.id != exceptId && normaliseCode(b.code) == wanted,
        );
    if (clash) throw DuplicateCodeException(code.trim());
  }

  void _checkPositive(int count, int avgWeightMg) {
    if (count <= 0) throw ArgumentError.value(count, 'count');
    if (avgWeightMg <= 0) throw ArgumentError.value(avgWeightMg, 'avgWeightMg');
  }

  void _checkMove(TransferInput input) {
    if (input.fromPondId == input.toPondId) {
      throw ArgumentError.value(input.toPondId, 'toPondId', 'same pond');
    }
    if (input.count <= 0) throw ArgumentError.value(input.count, 'count');
  }

  DateTime? _date(DateTime? d) => d == null ? null : farmDateToUtc(d);

  /// Emits [load] now and again whenever one of [tables] changes.
  Stream<T> _watch<T>(
    Set<TableInfo<Table, Object?>> tables,
    Future<T> Function() load,
  ) async* {
    yield await load();
    await for (final _ in db.tableUpdates(
      TableUpdateQuery.onAllTables(tables),
    )) {
      yield await load();
    }
  }
}

/// Fish per (batch, pond) from the current stockings, moves, samples and
/// daily-log deaths.
Future<List<Placement>> currentPlacements(AppDatabase db) async => placements(
  stockings: [
    for (final s in await _currentStockingsIn(db))
      StockingFact(
        batchId: s.batchId,
        pondId: s.pondId,
        count: s.count,
        avgWeightG: s.avgWeightMg / 1000,
        date: s.recordedAt,
      ),
  ],
  transfers: [
    for (final t in await _currentTransfersIn(db))
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
    for (final s in await _current(db, db.samples).get())
      SampleFact(
        batchId: s.batchId,
        pondId: s.pondId,
        avgWeightG: s.totalWeightG / s.fishCount,
        date: s.recordedAt,
      ),
  ],
  deaths: [
    for (final l in await (_current(
      db,
      db.dailyLogs,
    )..where((l) => l.deaths.isBiggerThanValue(0))).get())
      DeathFact(pondId: l.pondId, count: l.deaths, date: l.recordedAt),
  ],
);

/// Tables whose changes move fish or their weight.
Set<TableInfo<Table, Object?>> placementTables(AppDatabase db) => {
  db.stockings,
  db.transfers,
  db.samples,
  db.dailyLogs,
};

Future<List<Stocking>> _currentStockingsIn(AppDatabase db) =>
    _current(db, db.stockings).get();

Future<List<Transfer>> _currentTransfersIn(AppDatabase db) =>
    _current(db, db.transfers).get();

/// Current rows of an event table in a fixed order: recorded date, then
/// device creation time, then id, so same-day facts don't depend on
/// SQLite's row order.
SimpleSelectStatement<T, D> _current<T extends HasResultSet, D>(
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
