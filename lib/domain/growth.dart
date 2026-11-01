import 'dates.dart';
import 'farm_facts.dart';
import 'fcr.dart';
import 'occupancy.dart';
import 'stock.dart';

/// A moment the weight of a batch in a pond is known: its arrival, then
/// each sample. Counts are those at the end of that farm day, estimated.
class WeighPoint {
  const WeighPoint({
    required this.date,
    required this.avgWeightG,
    required this.liveCount,
    required this.biomassG,
    required this.fromSample,
  });

  final DateTime date;
  final double avgWeightG;
  final int liveCount;
  final int biomassG;
  final bool fromSample;
}

/// Growth between two weighing points.
class FcrPeriod {
  const FcrPeriod({
    required this.from,
    required this.to,
    required this.feedG,
    required this.fcr,
  });

  final DateTime from;
  final DateTime to;

  /// The pond's feed after [from]'s day up to and including [to]'s.
  final int feedG;

  /// Null when another batch shared the pond: its feed can't be split.
  final FcrResult? fcr;
}

enum FcrTrend { better, same, worse }

Placement? _pair(FarmFacts f, String batchId, String pondId, DateTime until) =>
    placementsOf(
      f,
      until: until,
    ).where((p) => p.batchId == batchId && p.pondId == pondId).firstOrNull;

/// The arrival of [batchId] in [pondId] (first stocking or move in), then
/// each sample of it there, oldest first. A sample on the arrival day
/// replaces the arrival point; of two samples on one day the later counts.
List<WeighPoint> weighPoints(
  FarmFacts f, {
  required String batchId,
  required String pondId,
}) {
  final arrivals = [
    for (final s in f.stockings)
      if (s.batchId == batchId && s.pondId == pondId) s.date,
    for (final t in f.transfers)
      if (t.batchId == batchId && t.toPondId == pondId) t.date,
  ];
  if (arrivals.isEmpty) return const [];
  final arrival = arrivals.reduce((a, b) => b.isBefore(a) ? b : a);

  // One sample per farm day, the last in list order (as placements do).
  final samplesByDay = <DateTime, SampleFact>{};
  for (final s in f.samples) {
    if (s.batchId == batchId && s.pondId == pondId) {
      samplesByDay[farmDate(s.date)] = s;
    }
  }
  final samples = samplesByDay.values.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  WeighPoint? point(DateTime date, double? sampled) {
    final p = _pair(f, batchId, pondId, date);
    final avg = sampled ?? p?.avgWeightG;
    if (p == null || avg == null) return null;
    return WeighPoint(
      date: date,
      avgWeightG: avg,
      liveCount: p.live.count,
      biomassG: biomassG(liveCount: p.live.count, avgWeightG: avg),
      fromSample: sampled != null,
    );
  }

  final sampledOnArrival = samples.any(
    (s) => daysBetween(s.date, arrival) == 0,
  );
  return [
    if (!sampledOnArrival) ?point(arrival, null),
    for (final s in samples)
      if (daysBetween(arrival, s.date) >= 0) ?point(s.date, s.avgWeightG),
  ];
}

/// Period FCR between consecutive [weighPoints]. Moves out of or into the
/// pond in a period count at their own weight, or the earlier point's when
/// not weighed. DOMAIN §Formulas.
List<FcrPeriod> fcrPeriods(
  FarmFacts f, {
  required String batchId,
  required String pondId,
}) {
  final points = weighPoints(f, batchId: batchId, pondId: pondId);
  if (points.length < 2) return const [];
  final pondFeed = [
    for (final l in countedLogs(f))
      if (l.pondId == pondId && l.feedG != 0) (farmDayNumber(l.date), l.feedG),
  ];
  bool inPeriod(DateTime d, WeighPoint a, WeighPoint b) =>
      daysBetween(a.date, d) > 0 && daysBetween(d, b.date) >= 0;

  return [
    for (var i = 1; i < points.length; i++)
      () {
        final a = points[i - 1], b = points[i];
        final from = farmDayNumber(a.date), to = farmDayNumber(b.date);
        var feedG = 0;
        for (final (day, g) in pondFeed) {
          if (day > from && day <= to) feedG += g;
        }
        var outG = 0, inG = 0;
        for (final t in f.transfers) {
          if (t.batchId != batchId || !inPeriod(t.date, a, b)) continue;
          final g = (t.count * (t.avgWeightG ?? a.avgWeightG)).round();
          if (t.fromPondId == pondId) outG += g;
          if (t.toPondId == pondId) inG += g;
        }
        // Another batch arriving in the period shared the feed, even if it
        // left the same day and no end-of-day state shows it.
        final visited =
            f.stockings.any(
              (s) =>
                  s.pondId == pondId &&
                  s.batchId != batchId &&
                  inPeriod(s.date, a, b),
            ) ||
            f.transfers.any(
              (t) =>
                  t.toPondId == pondId &&
                  t.batchId != batchId &&
                  inPeriod(t.date, a, b),
            );
        final shared =
            visited ||
            _shared(f, batchId, pondId, [
              a.date,
              b.date,
              for (final s in f.stockings)
                if (s.pondId == pondId && inPeriod(s.date, a, b)) s.date,
              for (final t in f.transfers)
                if ((t.toPondId == pondId || t.fromPondId == pondId) &&
                    inPeriod(t.date, a, b))
                  t.date,
            ]);
        return FcrPeriod(
          from: a.date,
          to: b.date,
          feedG: feedG,
          fcr: shared
              ? null
              : periodFcr(
                  feedG: feedG,
                  biomassPrevG: a.biomassG,
                  biomassNowG: b.biomassG,
                  outWeightG: outG,
                  inWeightG: inG,
                ),
        );
      }(),
  ];
}

/// True when another batch had fish in [pondId] at the end of any of
/// [dates].
bool _shared(
  FarmFacts f,
  String batchId,
  String pondId,
  List<DateTime> dates,
) => dates.any(
  (d) => placementsOf(
    f,
    until: d,
  ).any((p) => p.pondId == pondId && p.batchId != batchId && p.live.count > 0),
);

/// The latest computable period against the one before it; null when the
/// latest period has no value. Equal to 2 decimals is [FcrTrend.same].
FcrTrend? fcrTrend(List<FcrPeriod> periods) {
  if (periods.isEmpty) return null;
  final latest = periods.last.fcr;
  if (latest is! FcrValue) return null;
  final earlier = periods
      .sublist(0, periods.length - 1)
      .map((p) => p.fcr)
      .whereType<FcrValue>()
      .lastOrNull;
  if (earlier == null) return null;
  final now = (latest.value * 100).round(),
      before = (earlier.value * 100).round();
  if (now > before) return FcrTrend.worse;
  if (now < before) return FcrTrend.better;
  return FcrTrend.same;
}

/// Live fish of [batchId] over all ponds ÷ fish stocked; moves between
/// ponds neither add nor remove. Null when nothing was stocked.
double? batchSurvival(FarmFacts f, String batchId) {
  final stocked = f.stockings
      .where((s) => s.batchId == batchId)
      .fold(0, (n, s) => n + s.count);
  final live = placementsOf(f)
      .where((p) => p.batchId == batchId)
      .fold(0, (n, p) => n + p.live.count);
  return survivalRate(live: live, entered: stocked);
}

/// Fish in [pondId] before any of [day]'s records.
int liveInPondAtDayStart(FarmFacts f, String pondId, DateTime day) =>
    placementsOf(
      f,
      until: day.subtract(const Duration(days: 1)),
    ).where((p) => p.pondId == pondId).fold(0, (n, p) => n + p.live.count);

/// Deaths logged in [pondId] per farm day from [from] to [to], both
/// included; 0 for days without any.
List<int> dailyDeaths(
  FarmFacts f,
  String pondId, {
  required DateTime from,
  required DateTime to,
}) {
  final n = daysBetween(from, to) + 1;
  if (n <= 0) return const [];
  final out = List.filled(n, 0);
  for (final l in countedLogs(f)) {
    if (l.pondId != pondId || l.deaths == 0) continue;
    final i = daysBetween(from, l.date);
    if (i >= 0 && i < n) out[i] += l.deaths;
  }
  return out;
}
