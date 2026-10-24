import 'package:drift/drift.dart';

import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../session.dart';

/// One pond-day as entered on the daily log screen or a paper sheet.
class DailyLogInput {
  const DailyLogInput({
    required this.pondId,
    required this.date,
    required this.feedGivenG,
    this.feedings,
    this.leftover,
    this.ateFast = false,
    this.deaths = 0,
    this.deathSigns = const {},
    this.warningSigns = const {},
    this.waterColour,
    this.note,
    this.observedBy,
  });

  final String pondId;

  /// Date only.
  final DateTime date;
  final int feedGivenG;
  final int? feedings;
  final Leftover? leftover;
  final bool ateFast;
  final int deaths;
  final Set<WarningSign> deathSigns;
  final Set<WarningSign> warningSigns;
  final WaterColour? waterColour;
  final String? note;

  /// The person whose paper sheet this is (transcription).
  final String? observedBy;
}

/// Daily logs (SPEC F3). One current log per pond-day on this phone: saving
/// a day that already has one supersedes it.
class DailyLogRepository {
  DailyLogRepository(this.db, this.session, {this.visitId});

  final AppDatabase db;
  final Session session;

  /// The visit open on this phone, stamped on every log.
  final String? visitId;

  Future<String> save(DailyLogInput input) async {
    if (input.feedGivenG < 0) {
      throw ArgumentError.value(input.feedGivenG, 'feedGivenG');
    }
    if (input.deaths < 0) throw ArgumentError.value(input.deaths, 'deaths');
    return db.transaction(() async {
      final existing = await forDay(input.pondId, input.date);
      final row = _row(input);
      return existing == null
          ? _insert(row)
          : db.supersede(db.dailyLogs, existing.id, row);
    });
  }

  Future<void> saveWeek(List<DailyLogInput> inputs) => db.transaction(() async {
    for (final input in inputs) {
      await save(input);
    }
  });

  /// The current log of [pondId] on the farm date [date].
  Future<DailyLog?> forDay(String pondId, DateTime date) =>
      (_current()..where(
            (l) =>
                l.pondId.equals(pondId) &
                l.recordedAt.equals(farmDateToUtc(date)),
          ))
          .getSingleOrNull();

  /// Current logs dated [from] to [to] (farm dates, both included).
  Stream<List<DailyLog>> watchRange(DateTime from, DateTime to) =>
      (_current()..where(
            (l) => l.recordedAt.isBetweenValues(
              farmDateToUtc(from),
              farmDateToUtc(to),
            ),
          ))
          .watch();

  Stream<Set<String>> watchLoggedPondsOn(DateTime date) =>
      (_current()..where((l) => l.recordedAt.equals(farmDateToUtc(date))))
          .watch()
          .map((logs) => {for (final l in logs) l.pondId});

  /// The pond's most recent log before [date]: its leftovers adjust the
  /// day's ration.
  Future<DailyLog?> lastBefore(String pondId, DateTime date) =>
      (_current()
            ..where(
              (l) =>
                  l.pondId.equals(pondId) &
                  l.recordedAt.isSmallerThanValue(farmDateToUtc(date)),
            )
            ..orderBy([(l) => OrderingTerm.desc(l.recordedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Each pond's most recent log in the [days] before [date]: its leftovers
  /// adjust that day's ration.
  Stream<Map<String, DailyLog>> watchLatestBefore(
    DateTime date, {
    int days = 30,
  }) =>
      (_current()
            ..where(
              (l) => l.recordedAt.isBetweenValues(
                farmDateToUtc(date.subtract(Duration(days: days))),
                farmDateToUtc(date.subtract(const Duration(days: 1))),
              ),
            )
            ..orderBy([(l) => OrderingTerm.asc(l.recordedAt)]))
          .watch()
          .map((logs) => {for (final l in logs) l.pondId: l});

  Future<void> delete(String id) => db.tombstone(db.dailyLogs, id, session);

  SimpleSelectStatement<$DailyLogsTable, DailyLog> _current() =>
      db.select(db.dailyLogs)..where((_) => isCurrentEvent(db.dailyLogs));

  Future<String> _insert(DailyLogsCompanion row) async {
    final inserted = await db.into(db.dailyLogs).insertReturning(row);
    return inserted.id;
  }

  DailyLogsCompanion _row(DailyLogInput input) => DailyLogsCompanion.insert(
    associationId: session.associationId,
    enteredBy: session.userId,
    observedBy: Value(input.observedBy),
    deviceId: session.deviceId,
    recordedAt: farmDateToUtc(input.date),
    visitId: Value(visitId),
    pondId: input.pondId,
    feedGivenG: input.feedGivenG,
    feedings: Value(input.feedings),
    leftover: Value(input.leftover),
    ateFast: Value(input.ateFast),
    deaths: Value(input.deaths),
    deathSigns: Value(input.deathSigns),
    warningSigns: Value(input.warningSigns),
    waterColour: Value(input.waterColour),
    note: Value(input.note),
  );
}
