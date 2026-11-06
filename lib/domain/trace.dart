import 'dates.dart';
import 'farm_facts.dart';
import 'fcr.dart';
import 'growth.dart';
import 'occupancy.dart';
import 'types.dart';

/// A batch's numbers for its traceability sheet (SPEC F12, Annex C).
class BatchTrace {
  const BatchTrace({
    required this.stockedCount,
    required this.stockedWeightG,
    required this.harvestedCount,
    required this.harvestedWeightG,
    required this.unaccounted,
    required this.live,
    required this.survival,
    required this.cycleFcr,
    required this.batchFeedG,
  });

  final int stockedCount;
  final int stockedWeightG;
  final int harvestedCount;
  final int harvestedWeightG;

  /// Fish the estimate still counted when final harvests emptied ponds.
  final int unaccounted;

  /// Estimated fish still in ponds.
  final int live;
  final double? survival;

  /// Null until the batch is closed.
  final FcrResult? cycleFcr;

  /// Estimated: a shared pond's feed is split by biomass.
  final int batchFeedG;
}

BatchTrace batchTrace(
  FarmFacts f,
  String batchId, {
  required BatchStatus status,
}) {
  var stockedCount = 0, stockedG = 0.0;
  for (final s in f.stockings) {
    if (s.batchId != batchId) continue;
    stockedCount += s.count;
    stockedG += s.count * s.avgWeightG;
  }
  var harvestedCount = 0, harvestedG = 0;
  for (final h in f.harvests) {
    if (h.batchId != batchId) continue;
    harvestedCount += h.count;
    harvestedG += h.weightG;
  }
  var live = 0, unaccounted = 0;
  for (final p in placementsOf(f)) {
    if (p.batchId != batchId) continue;
    live += p.live.count;
    unaccounted += p.unaccounted;
  }
  final feedG = _batchFeed(f, batchId).round();
  return BatchTrace(
    stockedCount: stockedCount,
    stockedWeightG: stockedG.round(),
    harvestedCount: harvestedCount,
    harvestedWeightG: harvestedG,
    unaccounted: unaccounted,
    live: live,
    survival: batchSurvival(f, batchId),
    cycleFcr: status == BatchStatus.closed
        ? cycleFcr(
            totalFeedG: feedG,
            harvestedG: harvestedG,
            stockedG: stockedG.round(),
          )
        : null,
    batchFeedG: feedG,
  );
}

/// Each counted pond-day's feed shared between the batches in the pond at
/// the start of that day, by biomass; at the end of it when the pond was
/// empty that morning (plan M7 Decision 10).
double _batchFeed(FarmFacts f, String batchId) {
  var total = 0.0;
  for (final log in countedLogs(f)) {
    if (log.feedG <= 0) continue;
    final d = farmDate(log.date);
    var here = _inPond(
      placementsOf(f, until: DateTime(d.year, d.month, d.day - 1)),
      log.pondId,
    );
    if (here.isEmpty) here = _inPond(placementsOf(f, until: d), log.pondId);
    double mass(Placement p) => p.live.count * (p.avgWeightG ?? 1);
    final all = here.fold(0.0, (n, p) => n + mass(p));
    if (all <= 0) continue;
    for (final p in here) {
      if (p.batchId == batchId) total += log.feedG * mass(p) / all;
    }
  }
  return total;
}

List<Placement> _inPond(List<Placement> ps, String pondId) => [
  for (final p in ps)
    if (p.pondId == pondId && p.live.count > 0) p,
];
