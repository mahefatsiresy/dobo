import 'package:drift/drift.dart';

import '../../domain/config.dart';
import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../session.dart';
import '../sync_state.dart';
import 'errors.dart';
import 'feed_repository.dart';

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
    this.feedLotId,
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

  /// The lot the feed came from; null stamps the default lot.
  final String? feedLotId;
}

/// Daily logs (SPEC F3). One current log per pond-day on this phone: saving
/// a day that already has one supersedes it.
class DailyLogRepository {
  DailyLogRepository(
    this.db,
    this.session, {
    this.visitId,
    this.config = DomainConfig.defaults,
  });

  final AppDatabase db;
  final Session session;

  /// For the default feed lot (plan M7 Decision 5).
  final DomainConfig config;

  /// The visit open on this phone, stamped on every log.
  final String? visitId;

  Future<String> save(DailyLogInput input) async {
    if (input.feedGivenG < 0) {
      throw ArgumentError.value(input.feedGivenG, 'feedGivenG');
    }
    if (input.deaths < 0) throw ArgumentError.value(input.deaths, 'deaths');
    return db.transaction(() async {
      final existing = await forDay(input.pondId, input.date);
      final lotId =
          input.feedLotId ??
          existing?.feedLotId ??
          await FeedRepository(
            db,
            session,
            config: config,
          ).defaultLotFor(input.pondId, input.date);
      final row = _row(input).copyWith(feedLotId: Value(lotId));
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

  /// The current log of [pondId] on the farm date [date]. Two phones can
  /// both log a pond-day offline; after sync both are current (flagged in
  /// M5), and the newest one is the one shown and corrected here.
  Future<DailyLog?> forDay(String pondId, DateTime date) =>
      (_current()
            ..where(
              (l) =>
                  l.pondId.equals(pondId) &
                  l.recordedAt.equals(farmDateToUtc(date)),
            )
            ..orderBy([
              (l) => OrderingTerm.desc(l.createdAtDevice),
              (l) => OrderingTerm.desc(l.id),
            ])
            ..limit(1))
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
                farmDateToUtc(DateTime(date.year, date.month, date.day - days)),
                farmDateToUtc(DateTime(date.year, date.month, date.day - 1)),
              ),
            )
            ..orderBy([(l) => OrderingTerm.asc(l.recordedAt)]))
          .watch()
          .map((logs) => {for (final l in logs) l.pondId: l});

  Future<void> delete(String id) => db.tombstone(db.dailyLogs, id, session);

  /// Every current log of [pondId] on [date], newest first: more than one
  /// means two phones logged the day (SPEC §7).
  Stream<List<DailyLog>> watchCurrentForDay(String pondId, DateTime date) =>
      (_current()
            ..where(
              (l) =>
                  l.pondId.equals(pondId) &
                  l.recordedAt.equals(farmDateToUtc(date)),
            )
            ..orderBy([
              (l) => OrderingTerm.desc(l.createdAtDevice),
              (l) => OrderingTerm.desc(l.id),
            ]))
          .watch();

  /// Resolves a duplicate pond-day: [discardIds] each get a tombstone and
  /// the kept log is written again as its own correction, all or none. The
  /// copy keeps who entered and observed it. Two phones keeping opposite
  /// logs offline then leave both copies current (still flagged), never
  /// none. Throws [StaleEventException] when [keepId] or one of
  /// [discardIds] is no longer current. Returns the copy's id.
  Future<String> keepOnly(String keepId, List<String> discardIds) =>
      db.transaction(() async {
        // Another phone may have discarded the one kept here.
        final kept = await (_current()..where((l) => l.id.equals(keepId)))
            .getSingleOrNull();
        if (kept == null) throw StaleEventException(keepId);
        for (final id in discardIds) {
          if (id != keepId) await delete(id);
        }
        return db.supersede(
          db.dailyLogs,
          keepId,
          RawValuesInsertable<DailyLog>({
            ...kept.toColumns(false),
            'device_id': Variable<String>(session.deviceId),
            'server_received_at': const Variable<DateTime>(null),
            'server_seq': const Variable<int>(null),
            'sync_state': Variable<String>(SyncState.pending.name),
            'sync_error': const Variable<String>(null),
          }),
        );
      });

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
