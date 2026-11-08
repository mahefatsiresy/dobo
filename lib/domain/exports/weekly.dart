import '../alerts/farm_alerts.dart';
import '../dates.dart';
import '../farm_facts.dart';

/// One pond's week on the weekly sheet (handbook Annex B).
class WeeklyRow {
  const WeeklyRow({
    required this.pondId,
    required this.weekStart,
    this.temperatureC,
    this.ph,
    this.oxygenMgL,
    this.feedG = 0,
    this.deaths = 0,
    this.loggedDays = 0,
    this.avgWeightGByBatch = const {},
  });

  final String pondId;

  /// The Monday, date-only.
  final DateTime weekStart;
  final double? temperatureC;
  final double? ph;
  final double? oxygenMgL;
  final int feedG;
  final int deaths;

  /// Pond-days with a daily log: with none, feed and deaths are unknown,
  /// not zero.
  final int loggedDays;

  /// Each batch's latest sample of the week in this pond.
  final Map<String, double> avgWeightGByBatch;

  /// Nothing recorded that week.
  bool get isEmpty =>
      temperatureC == null &&
      ph == null &&
      oxygenMgL == null &&
      loggedDays == 0 &&
      avgWeightGByBatch.isEmpty;
}

DateTime _monday(DateTime t) {
  final d = farmDate(t);
  return DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));
}

/// [from] to [to] widened to whole weeks: the Monday on or before [from]'s
/// farm day to the Sunday on or after [to]'s, date-only.
(DateTime, DateTime) wholeWeeks(DateTime from, DateTime to) {
  final last = _monday(to);
  return (_monday(from), DateTime(last.year, last.month, last.day + 6));
}

/// The weekly sheet over [from]–[to] widened to whole weeks, pond by pond
/// in [pondIds]' order, weeks oldest first (plan M8 Decision 8). A pond is
/// listed when it held fish in the range or has a record in it; its weeks
/// with nothing recorded are kept, so a missed check shows.
List<WeeklyRow> weeklySheet({
  required FarmFacts facts,
  List<(String pondId, ReadingInfo)> readings = const [],
  required DateTime from,
  required DateTime to,
  required List<String> pondIds,
}) {
  final (start, end) = wholeWeeks(from, to);
  final firstDay = farmDayNumber(start);
  final lastDay = farmDayNumber(end);
  final weeks = (lastDay - firstDay + 1) ~/ 7;
  // Week index of [t] in the range, or null when outside it.
  int? week(DateTime t) {
    final n = farmDayNumber(t) - firstDay;
    return n < 0 || n > lastDay - firstDay ? null : n ~/ 7;
  }

  final dayBefore = DateTime(start.year, start.month, start.day - 1);
  final heldAtStart = {
    for (final p in placementsOf(facts, until: dayBefore))
      if (p.live.count > 0) p.pondId,
  };
  final active = {
    ...heldAtStart,
    for (final s in facts.stockings)
      if (week(s.date) != null) s.pondId,
    for (final t in facts.transfers)
      if (week(t.date) != null) t.toPondId,
    for (final l in facts.logs)
      if (week(l.date) != null) l.pondId,
    for (final s in facts.samples)
      if (week(s.date) != null) s.pondId,
    for (final (pond, r) in readings)
      if (week(r.at) != null) pond,
  };

  final counted = countedLogs(facts);
  final sortedReadings = [...readings]
    ..sort((a, b) => a.$2.at.compareTo(b.$2.at));
  final rows = <WeeklyRow>[];
  for (final pond in pondIds) {
    if (!active.contains(pond)) continue;
    final temp = List<double?>.filled(weeks, null);
    final ph = List<double?>.filled(weeks, null);
    final oxygen = List<double?>.filled(weeks, null);
    final feed = List.filled(weeks, 0);
    final deaths = List.filled(weeks, 0);
    final logged = List.filled(weeks, 0);
    final weights = List.generate(weeks, (_) => <String, double>{});
    final sampledAt = List.generate(weeks, (_) => <String, DateTime>{});
    // Oldest first, so the latest reading with a value wins.
    for (final (p, r) in sortedReadings) {
      final w = week(r.at);
      if (p != pond || w == null) continue;
      temp[w] = r.temperatureC ?? temp[w];
      ph[w] = r.ph ?? ph[w];
      oxygen[w] = r.oxygenMgL ?? oxygen[w];
    }
    for (final l in counted) {
      final w = week(l.date);
      if (l.pondId != pond || w == null) continue;
      feed[w] += l.feedG;
      deaths[w] += l.deaths;
      logged[w]++;
    }
    for (final s in facts.samples) {
      final w = week(s.date);
      if (s.pondId != pond || w == null) continue;
      final seen = sampledAt[w][s.batchId];
      if (seen == null || !s.date.isBefore(seen)) {
        sampledAt[w][s.batchId] = s.date;
        weights[w][s.batchId] = s.avgWeightG;
      }
    }
    for (var w = 0; w < weeks; w++) {
      rows.add(
        WeeklyRow(
          pondId: pond,
          weekStart: DateTime(start.year, start.month, start.day + 7 * w),
          temperatureC: temp[w],
          ph: ph[w],
          oxygenMgL: oxygen[w],
          feedG: feed[w],
          deaths: deaths[w],
          loggedDays: logged[w],
          avgWeightGByBatch: weights[w],
        ),
      );
    }
  }
  return rows;
}
