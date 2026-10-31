// Drift's own Batch (bulk writes) is not used here.
import 'package:drift/drift.dart' hide Batch;

import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../session.dart';
import 'watch_tables.dart';

/// A water reading at a moment (UTC instant).
class WaterReadingInput {
  const WaterReadingInput({
    required this.pondId,
    required this.at,
    this.temperatureC,
    this.ph,
    this.oxygenMgL,
    this.colour,
    this.renewedPct,
  });

  final String pondId;
  final DateTime at;
  final double? temperatureC;
  final double? ph;
  final double? oxygenMgL;
  final WaterColour? colour;
  final int? renewedPct;

  bool get isEmpty =>
      temperatureC == null &&
      ph == null &&
      oxygenMgL == null &&
      colour == null &&
      renewedPct == null;
}

class SampleInput {
  const SampleInput({
    required this.batchId,
    required this.pondId,
    required this.date,
    required this.fishCount,
    required this.totalWeightG,
  });

  final String batchId;
  final String pondId;

  /// Date only.
  final DateTime date;
  final int fishCount;
  final int totalWeightG;
}

/// Water readings and samples (SPEC §4, F5).
class ReadingRepository {
  ReadingRepository(this.db, this.session, {this.visitId});

  final AppDatabase db;
  final Session session;
  final String? visitId;

  Future<String> addWaterReading(WaterReadingInput input) async {
    _checkReading(input);
    final row = await db
        .into(db.waterReadings)
        .insertReturning(_reading(input));
    return row.id;
  }

  Future<String> correctWaterReading(String id, WaterReadingInput input) async {
    _checkReading(input);
    return db.supersede(db.waterReadings, id, _reading(input));
  }

  Future<void> deleteWaterReading(String id) =>
      db.tombstone(db.waterReadings, id, session);

  Stream<WaterReading?> watchLatestWaterReading(String pondId) =>
      (db.select(db.waterReadings)
            ..where(
              (r) => isCurrentEvent(db.waterReadings) & r.pondId.equals(pondId),
            )
            ..orderBy([(r) => OrderingTerm.desc(r.recordedAt)])
            ..limit(1))
          .watchSingleOrNull();

  /// Each pond's latest current water reading.
  Stream<Map<String, WaterReading>> watchLatestWaterReadings() =>
      (db.select(db.waterReadings)
            ..where((_) => isCurrentEvent(db.waterReadings))
            ..orderBy([
              (r) => OrderingTerm.asc(r.recordedAt),
              (r) => OrderingTerm.asc(r.createdAtDevice),
            ]))
          .watch()
          .map((rows) => {for (final r in rows) r.pondId: r});

  Future<String> addSample(SampleInput input) async {
    _checkSample(input);
    final row = await db.into(db.samples).insertReturning(_sample(input));
    return row.id;
  }

  Future<String> correctSample(String id, SampleInput input) async {
    _checkSample(input);
    return db.supersede(db.samples, id, _sample(input));
  }

  Future<void> deleteSample(String id) => db.tombstone(db.samples, id, session);

  /// Current samples of [batchId], newest first.
  Stream<List<Sample>> watchSamples(String batchId) =>
      (db.select(db.samples)
            ..where(
              (s) => isCurrentEvent(db.samples) & s.batchId.equals(batchId),
            )
            ..orderBy([(s) => OrderingTerm.desc(s.recordedAt)]))
          .watch();

  Stream<List<WaterReading>> watchReadingsForVisit(String visitId) =>
      (db.select(db.waterReadings)..where(
            (r) => isCurrentEvent(db.waterReadings) & r.visitId.equals(visitId),
          ))
          .watch();

  Stream<List<Sample>> watchSamplesForVisit(String visitId) =>
      (db.select(db.samples)..where(
            (s) => isCurrentEvent(db.samples) & s.visitId.equals(visitId),
          ))
          .watch();

  /// For each (batch, pond): its latest sample date, or, never sampled
  /// there, when fish of the batch first arrived in the pond. Sampling is
  /// due 14 days after it (DOMAIN §Sampling).
  Stream<Map<(String, String), DateTime>> watchLastSampleOrStocking() {
    Future<Map<(String, String), DateTime>> load() async {
      final arrived = <(String, String), DateTime>{};
      void arrive((String, String) key, DateTime at) {
        final seen = arrived[key];
        if (seen == null || at.isBefore(seen)) arrived[key] = at;
      }

      for (final s in await (db.select(
        db.stockings,
      )..where((_) => isCurrentEvent(db.stockings))).get()) {
        arrive((s.batchId, s.pondId), s.recordedAt);
      }
      for (final t in await (db.select(
        db.transfers,
      )..where((_) => isCurrentEvent(db.transfers))).get()) {
        arrive((t.batchId, t.toPondId), t.recordedAt);
      }
      final sampled = <(String, String), DateTime>{};
      for (final s in await (db.select(
        db.samples,
      )..where((_) => isCurrentEvent(db.samples))).get()) {
        final key = (s.batchId, s.pondId);
        final seen = sampled[key];
        if (seen == null || s.recordedAt.isAfter(seen)) {
          sampled[key] = s.recordedAt;
        }
      }
      return {...arrived, ...sampled};
    }

    return watchTables(db, {db.stockings, db.transfers, db.samples}, load);
  }

  void _checkReading(WaterReadingInput input) {
    if (input.isEmpty) throw ArgumentError('A water reading needs a value');
  }

  void _checkSample(SampleInput input) {
    if (input.fishCount <= 0) {
      throw ArgumentError.value(input.fishCount, 'fishCount');
    }
    if (input.totalWeightG <= 0) {
      throw ArgumentError.value(input.totalWeightG, 'totalWeightG');
    }
  }

  WaterReadingsCompanion _reading(WaterReadingInput input) =>
      WaterReadingsCompanion.insert(
        associationId: session.associationId,
        enteredBy: session.userId,
        deviceId: session.deviceId,
        recordedAt: input.at.toUtc(),
        visitId: Value(visitId),
        pondId: input.pondId,
        temperatureC: Value(input.temperatureC),
        ph: Value(input.ph),
        oxygenMgL: Value(input.oxygenMgL),
        colour: Value(input.colour),
        renewedPct: Value(input.renewedPct),
      );

  SamplesCompanion _sample(SampleInput input) => SamplesCompanion.insert(
    associationId: session.associationId,
    enteredBy: session.userId,
    deviceId: session.deviceId,
    recordedAt: farmDateToUtc(input.date),
    visitId: Value(visitId),
    batchId: input.batchId,
    pondId: input.pondId,
    fishCount: input.fishCount,
    totalWeightG: input.totalWeightG,
  );
}
