import 'package:drift/drift.dart';

import '../../domain/config.dart';
import '../../domain/dates.dart';
import '../../domain/prep.dart';
import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../session.dart';
import 'batch_repository.dart';
import 'errors.dart';
import 'facts_repository.dart';
import 'pond_repository.dart';
import 'watch_tables.dart';

/// Pond preparation (SPEC F10, plan M7 Decisions 1–3).
class PrepRepository {
  PrepRepository(this.db, this.session, {this.config = DomainConfig.defaults});

  final AppDatabase db;
  final Session session;
  final DomainConfig config;

  /// Records [step] done on [on] (a date). `rest` is recorded by
  /// [markReady] only. Throws [PondNotEmptyException] while the pond holds
  /// fish.
  Future<String> record(
    String pondId,
    PrepStep step, {
    required DateTime on,
    PrepProduct? product,
    int? doseG,
  }) async {
    if (step == PrepStep.rest) throw ArgumentError.value(step, 'step');
    return db.transaction(() async {
      await _checkEmpty(pondId);
      await _checkInCycle(pondId, on);
      final id = await _insert(pondId, step, on, product, doseG);
      final pond = await PondRepository(db, session).get(pondId);
      if (pond.status != PondStatus.ready &&
          pond.status != PondStatus.isolated) {
        await PondRepository(
          db,
          session,
        ).setStatus(pondId, PondStatus.preparing);
      }
      return id;
    });
  }

  /// Ends the rest after filling: the pond is ready to stock.
  Future<String> markReady(String pondId, {required DateTime on}) =>
      db.transaction(() async {
        await _checkEmpty(pondId);
        await _checkInCycle(pondId, on);
        final id = await _insert(pondId, PrepStep.rest, on, null, null);
        final pond = await PondRepository(db, session).get(pondId);
        if (pond.status != PondStatus.isolated) {
          await PondRepository(db, session).setStatus(pondId, PondStatus.ready);
        }
        return id;
      });

  Future<String> correct(
    String id, {
    required DateTime on,
    PrepProduct? product,
    int? doseG,
  }) => db.transaction(() async {
    final old = await (db.select(
      db.prepSteps,
    )..where((s) => s.id.equals(id))).getSingle();
    await _checkInCycle(old.pondId, on);
    return db.supersede(
      db.prepSteps,
      id,
      _row(old.pondId, old.step, on, product, doseG),
    );
  });

  Future<void> delete(String id) => db.tombstone(db.prepSteps, id, session);

  Future<PrepProgress> progress(String pondId) async =>
      (await allProgress())[pondId] ??
      prepProgress(
        pondId: pondId,
        steps: const [],
        lastDayWithFish: lastDayWithFish(await currentFacts(db), pondId),
        config: config,
      );

  Stream<PrepProgress> watchProgress(String pondId) => watchTables(db, {
    db.prepSteps,
    ...placementTables(db),
  }, () => progress(pondId));

  /// Every pond's current preparation, for ponds with a step on record.
  Future<Map<String, PrepProgress>> allProgress() async {
    final steps = [
      for (final s in await currentEvents(db, db.prepSteps).get())
        PrepStepFact(
          id: s.id,
          pondId: s.pondId,
          step: s.step,
          date: s.recordedAt,
          product: s.product,
          doseG: s.doseG,
        ),
    ];
    if (steps.isEmpty) return const {};
    final facts = await currentFacts(db);
    return {
      for (final pondId in {for (final s in steps) s.pondId})
        pondId: prepProgress(
          pondId: pondId,
          steps: steps,
          lastDayWithFish: lastDayWithFish(facts, pondId),
          config: config,
        ),
    };
  }

  Stream<Map<String, PrepProgress>> watchAll() =>
      watchTables(db, {db.prepSteps, ...placementTables(db)}, allProgress);

  /// A step dated while the pond still held fish would belong to no cycle:
  /// saved, but never shown.
  Future<void> _checkInCycle(String pondId, DateTime on) async {
    final start = (await progress(pondId)).cycleStart;
    if (start != null && daysBetween(start, on) < 0) {
      throw ArgumentError.value(on, 'on', 'before the preparation cycle');
    }
  }

  Future<void> _checkEmpty(String pondId) async {
    final occupied = (await currentPlacements(db)).any(
      (p) => p.pondId == pondId && (p.live.count > 0 || p.live.inconsistent),
    );
    if (occupied) throw PondNotEmptyException(pondId);
  }

  Future<String> _insert(
    String pondId,
    PrepStep step,
    DateTime on,
    PrepProduct? product,
    int? doseG,
  ) async =>
      (await db
              .into(db.prepSteps)
              .insertReturning(_row(pondId, step, on, product, doseG)))
          .id;

  PrepStepsCompanion _row(
    String pondId,
    PrepStep step,
    DateTime on,
    PrepProduct? product,
    int? doseG,
  ) => PrepStepsCompanion.insert(
    associationId: session.associationId,
    enteredBy: session.userId,
    deviceId: session.deviceId,
    recordedAt: farmDateToUtc(on),
    pondId: pondId,
    step: step,
    product: Value(product),
    doseG: Value(doseG),
  );
}
