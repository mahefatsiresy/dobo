import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';

/// A member's visits (SPEC F5). One open visit per phone; every record
/// entered while it is open carries its id.
class VisitRepository {
  VisitRepository(this.db, this.session);

  final AppDatabase db;
  final Session session;

  /// Throws [StateError] when this phone already has an open visit.
  Future<String> start() => db.transaction(() async {
    if (await _open().getSingleOrNull() != null) {
      throw StateError('A visit is already open');
    }
    final row = await db
        .into(db.visits)
        .insertReturning(
          VisitsCompanion.insert(
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            siteId: session.siteId,
            startedAt: utcNow(),
          ),
        );
    return row.id;
  });

  /// This phone's open visit, if any.
  Stream<Visit?> watchOpen() => _open().watchSingleOrNull();

  Future<void> setSummary(String id, String? summary) =>
      _write(id, VisitsCompanion(summary: Value(summary)));

  Future<void> end(String id) =>
      _write(id, VisitsCompanion(endedAt: Value(utcNow())));

  /// The site's visits, newest first.
  Stream<List<Visit>> watchAll() =>
      (db.select(db.visits)
            ..where((v) => v.siteId.equals(session.siteId))
            ..orderBy([(v) => OrderingTerm.desc(v.startedAt)]))
          .watch();

  SimpleSelectStatement<$VisitsTable, Visit> _open() =>
      db.select(db.visits)..where(
        (v) =>
            v.siteId.equals(session.siteId) &
            v.deviceId.equals(session.deviceId) &
            v.endedAt.isNull(),
      );

  Future<void> _write(String id, VisitsCompanion fields) =>
      (db.update(db.visits)..where((v) => v.id.equals(id))).write(
        fields.copyWith(
          updatedAtDevice: Value(utcNow()),
          syncState: const Value(SyncState.pending),
        ),
      );
}

/// Condition checks and free observations (SPEC F5).
class ObservationRepository {
  ObservationRepository(this.db, this.session, {this.visitId});

  final AppDatabase db;
  final Session session;
  final String? visitId;

  Future<String> addObservation({
    String? pondId,
    required ObservationCategory category,
    bool? ok,
    String? note,
  }) async {
    final row = await db
        .into(db.observations)
        .insertReturning(
          ObservationsCompanion.insert(
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            recordedAt: utcNow(),
            visitId: Value(visitId),
            siteId: session.siteId,
            pondId: Value(pondId),
            category: category,
            ok: Value(ok),
            note: Value(note),
          ),
        );
    return row.id;
  }

  /// Corrects an observation: a new row superseding [id].
  Future<String> correctObservation(
    String id, {
    String? pondId,
    required ObservationCategory category,
    bool? ok,
    String? note,
  }) => db.supersede(
    db.observations,
    id,
    ObservationsCompanion.insert(
      associationId: session.associationId,
      enteredBy: session.userId,
      deviceId: session.deviceId,
      recordedAt: utcNow(),
      visitId: Value(visitId),
      siteId: session.siteId,
      pondId: Value(pondId),
      category: category,
      ok: Value(ok),
      note: Value(note),
    ),
  );

  Future<void> delete(String id) => db.tombstone(db.observations, id, session);

  /// Current observations made during [visitId], oldest first.
  Stream<List<Observation>> watchForVisit(String visitId) =>
      (db.select(db.observations)
            ..where(
              (o) =>
                  isCurrentEvent(db.observations) & o.visitId.equals(visitId),
            )
            ..orderBy([(o) => OrderingTerm.asc(o.recordedAt)]))
          .watch();
}
