import 'package:drift/drift.dart';

import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../session.dart';
import 'pond_repository.dart';

/// A treatment given on someone's advice; the app never suggests one.
class TreatmentInput {
  const TreatmentInput({
    required this.pondId,
    this.batchId,
    required this.date,
    required this.product,
    required this.dose,
    this.advisedBy,
  });

  final String pondId;
  final String? batchId;

  /// Date only.
  final DateTime date;
  final String product;
  final String dose;
  final String? advisedBy;
}

/// Health events, isolation and treatments (SPEC F9).
class HealthRepository {
  HealthRepository(this.db, this.session, {this.visitId});

  final AppDatabase db;
  final Session session;
  final String? visitId;

  /// Records what was seen and done. Isolating sets the pond `isolated`:
  /// no fish leave it until [release].
  Future<String> report({
    required String pondId,
    required Set<WarningSign> signs,
    String? suspectedIssue,
    required bool isolate,
    required bool technicianCalled,
  }) => db.transaction(() async {
    final id = await _event(pondId, signs, suspectedIssue, {
      if (isolate) HealthAction.isolated,
      if (technicianCalled) HealthAction.technicianCalled,
    });
    if (isolate) {
      await PondRepository(db, session).setStatus(pondId, PondStatus.isolated);
    }
    return id;
  });

  /// Lifts isolation with its own event; the pond then shows what its fish
  /// give.
  Future<String> release(String pondId) => db.transaction(() async {
    final id = await _event(pondId, const {}, null, {HealthAction.released});
    await PondRepository(db, session).setStatus(pondId, PondStatus.empty);
    return id;
  });

  Future<String> addTreatment(TreatmentInput input) async {
    if (input.product.trim().isEmpty) {
      throw ArgumentError.value(input.product, 'product');
    }
    if (input.dose.trim().isEmpty) {
      throw ArgumentError.value(input.dose, 'dose');
    }
    final row = await db
        .into(db.treatments)
        .insertReturning(
          TreatmentsCompanion.insert(
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            recordedAt: farmDateToUtc(input.date),
            visitId: Value(visitId),
            pondId: input.pondId,
            batchId: Value(input.batchId),
            product: input.product.trim(),
            dose: input.dose.trim(),
            advisedBy: Value(input.advisedBy),
          ),
        );
    return row.id;
  }

  /// Current health events of [pondId], newest first.
  Stream<List<HealthEvent>> watchForPond(String pondId) =>
      (db.select(db.healthEvents)
            ..where(
              (e) => isCurrentEvent(db.healthEvents) & e.pondId.equals(pondId),
            )
            ..orderBy([
              (e) => OrderingTerm.desc(e.recordedAt),
              (e) => OrderingTerm.desc(e.createdAtDevice),
            ]))
          .watch();

  /// Current treatments of [pondId], newest first.
  Stream<List<Treatment>> watchTreatments(String pondId) =>
      (db.select(db.treatments)
            ..where(
              (t) => isCurrentEvent(db.treatments) & t.pondId.equals(pondId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
          .watch();

  Future<String> _event(
    String pondId,
    Set<WarningSign> signs,
    String? suspectedIssue,
    Set<HealthAction> actions,
  ) async {
    final row = await db
        .into(db.healthEvents)
        .insertReturning(
          HealthEventsCompanion.insert(
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            recordedAt: DateTime.now().toUtc(),
            visitId: Value(visitId),
            pondId: pondId,
            signs: Value(signs),
            suspectedIssue: Value(suspectedIssue),
            actions: actions,
          ),
        );
    return row.id;
  }
}
