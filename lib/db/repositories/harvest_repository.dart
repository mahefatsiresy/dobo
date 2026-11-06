import 'package:drift/drift.dart';

import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';
import 'batch_repository.dart';
import 'errors.dart';
import 'facts_repository.dart';
import 'pond_repository.dart';
import 'watch_tables.dart';

class HarvestInput {
  const HarvestInput({
    required this.batchId,
    required this.pondId,
    required this.date,
    required this.count,
    required this.weightG,
    required this.isFinal,
  });

  final String batchId;
  final String pondId;

  /// Date only.
  final DateTime date;
  final int count;
  final int weightG;
  final bool isFinal;
}

class SaleInput {
  const SaleInput({
    required this.harvestId,
    required this.customerId,
    required this.date,
    required this.weightG,
    required this.form,
    this.deliveryNote,
  });

  final String harvestId;
  final String customerId;

  /// Date only.
  final DateTime date;
  final int weightG;
  final ProductForm form;
  final String? deliveryNote;
}

class HarvestWithSales {
  const HarvestWithSales(this.harvest, this.sales);

  final Harvest harvest;
  final List<Sale> sales;
}

/// Harvests and sales (SPEC F12, plan M7 Decisions 8, 9 and 11). Every
/// harvest write recomputes the batch's status and the pond's.
class HarvestRepository {
  HarvestRepository(this.db, this.session);

  final AppDatabase db;
  final Session session;

  /// Throws [PondIsolatedException] for an isolated pond: no fish leave it.
  Future<String> harvest(HarvestInput input) async {
    _check(input.count, input.weightG);
    return db.transaction(() async {
      final pond = await PondRepository(db, session).get(input.pondId);
      if (pond.status == PondStatus.isolated) {
        throw PondIsolatedException(pond.id);
      }
      final id = (await db.into(db.harvests).insertReturning(_harvest(input)))
          .id;
      await _refresh(input.batchId, input.pondId);
      return id;
    });
  }

  Future<String> correct(String id, HarvestInput input) async {
    _check(input.count, input.weightG);
    return db.transaction(() async {
      final old = await _get(id);
      final newId = await db.supersede(db.harvests, id, _harvest(input));
      await _refresh(old.batchId, old.pondId);
      await _refresh(input.batchId, input.pondId);
      return newId;
    });
  }

  Future<void> delete(String id) => db.transaction(() async {
    final old = await _get(id);
    await db.tombstone(db.harvests, id, session);
    await _refresh(old.batchId, old.pondId);
  });

  Future<String> sell(SaleInput input) async {
    if (input.weightG <= 0) throw ArgumentError.value(input.weightG, 'weightG');
    return db.transaction(() async {
      final h = await _get(input.harvestId);
      return (await db
              .into(db.sales)
              .insertReturning(_sale(input, batchId: h.batchId)))
          .id;
    });
  }

  Future<String> correctSale(String id, SaleInput input) =>
      db.transaction(() async {
        final h = await _get(input.harvestId);
        return db.supersede(db.sales, id, _sale(input, batchId: h.batchId));
      });

  Future<void> deleteSale(String id) => db.tombstone(db.sales, id, session);

  /// [batchId]'s harvests, newest first, each with its sales.
  Stream<List<HarvestWithSales>> watchForBatch(String batchId) =>
      watchTables(db, {db.harvests, db.sales}, () async {
        final sales = await (currentEvents(
          db,
          db.sales,
        )..where((s) => s.batchId.equals(batchId))).get();
        final harvests = await (currentEvents(
          db,
          db.harvests,
        )..where((h) => h.batchId.equals(batchId))).get();
        return [
          for (final h in harvests.reversed)
            HarvestWithSales(h, [
              for (final s in sales)
                if (s.harvestId == h.id) s,
            ]),
        ];
      });

  Future<Harvest> _get(String id) =>
      (db.select(db.harvests)..where((h) => h.id.equals(id))).getSingle();

  /// The batch is harvesting once fish left it, closed when a final
  /// harvest left none anywhere, active again when its harvests are gone.
  /// The pond is empty once its fish are gone, stocked when they are back.
  Future<void> _refresh(String batchId, String pondId) async {
    final placements = await currentPlacements(db);
    final harvests = await (currentEvents(
      db,
      db.harvests,
    )..where((h) => h.batchId.equals(batchId))).get();
    final batch = await (db.select(
      db.batches,
    )..where((b) => b.id.equals(batchId))).getSingleOrNull();
    if (batch != null) {
      final live = placements
          .where((p) => p.batchId == batchId)
          .fold(0, (n, p) => n + p.live.count);
      final BatchStatus status;
      if (harvests.isEmpty) {
        status =
            batch.status == BatchStatus.harvesting ||
                batch.status == BatchStatus.closed
            ? BatchStatus.active
            : batch.status;
      } else {
        status = live == 0 && harvests.any((h) => h.isFinal)
            ? BatchStatus.closed
            : BatchStatus.harvesting;
      }
      if (status != batch.status) {
        await (db.update(db.batches)..where((b) => b.id.equals(batchId))).write(
          BatchesCompanion(
            status: Value(status),
            updatedAtDevice: Value(utcNow()),
            syncState: const Value(SyncState.pending),
          ),
        );
      }
    }

    final ponds = PondRepository(db, session);
    final pond = await ponds.get(pondId);
    final fish = placements.any(
      (p) => p.pondId == pondId && (p.live.count > 0 || p.live.inconsistent),
    );
    if (pond.status == PondStatus.isolated) return;
    if (!fish && pond.status == PondStatus.stocked) {
      await ponds.setStatus(pondId, PondStatus.empty);
    } else if (fish && pond.status != PondStatus.stocked) {
      await ponds.setStatus(pondId, PondStatus.stocked);
    }
  }

  void _check(int count, int weightG) {
    if (count <= 0) throw ArgumentError.value(count, 'count');
    if (weightG <= 0) throw ArgumentError.value(weightG, 'weightG');
  }

  HarvestsCompanion _harvest(HarvestInput i) => HarvestsCompanion.insert(
    associationId: session.associationId,
    enteredBy: session.userId,
    deviceId: session.deviceId,
    recordedAt: farmDateToUtc(i.date),
    batchId: i.batchId,
    pondId: i.pondId,
    count: i.count,
    weightG: i.weightG,
    isFinal: i.isFinal,
  );

  SalesCompanion _sale(SaleInput i, {required String batchId}) =>
      SalesCompanion.insert(
        associationId: session.associationId,
        enteredBy: session.userId,
        deviceId: session.deviceId,
        recordedAt: farmDateToUtc(i.date),
        harvestId: i.harvestId,
        batchId: batchId,
        customerId: i.customerId,
        weightG: i.weightG,
        form: i.form,
        deliveryNote: Value(
          i.deliveryNote == null || i.deliveryNote!.trim().isEmpty
              ? null
              : i.deliveryNote!.trim(),
        ),
      );
}
