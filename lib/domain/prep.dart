import 'config.dart';
import 'dates.dart';
import 'farm_facts.dart';
import 'types.dart';

/// A preparation step done on a pond.
class PrepStepFact {
  const PrepStepFact({
    required this.id,
    required this.pondId,
    required this.step,
    required this.date,
    this.product,
    this.doseG,
  });

  final String id;
  final String pondId;
  final PrepStep step;
  final DateTime date;
  final PrepProduct? product;
  final int? doseG;
}

/// Where a pond's current preparation stands (DOMAIN §Pond preparation).
class PrepProgress {
  const PrepProgress({
    required this.done,
    required this.next,
    required this.dryUntilMin,
    required this.dryUntilMax,
    required this.restUntil,
    required this.canMarkReady,
    required this.skipped,
    this.cycleStart,
  });

  /// The current cycle's steps, in checklist order; the latest of each.
  final Map<PrepStep, PrepStepFact> done;

  /// The first step not done; null when all are.
  final PrepStep? next;

  /// Farm dates the drying should end, after draining.
  final DateTime? dryUntilMin;
  final DateTime? dryUntilMax;

  /// Farm date the rest after filling ends.
  final DateTime? restUntil;

  /// Filled: the pond may be marked ready to stock.
  final bool canMarkReady;

  /// Steps before the furthest one done that were not done.
  final List<PrepStep> skipped;

  /// The first farm day a step of this cycle may be dated: the day after
  /// the pond last held fish; null when it never did.
  final DateTime? cycleStart;
}

/// The current cycle of [pondId]: steps dated after [lastDayWithFish] (all
/// its steps when it never held fish). Plan M7 Decisions 1–3.
PrepProgress prepProgress({
  required String pondId,
  required List<PrepStepFact> steps,
  required DateTime? lastDayWithFish,
  required DomainConfig config,
}) {
  final latest = <PrepStep, PrepStepFact>{};
  for (final s in steps) {
    if (s.pondId != pondId) continue;
    if (lastDayWithFish != null && daysBetween(lastDayWithFish, s.date) <= 0) {
      continue;
    }
    final had = latest[s.step];
    if (had == null || had.date.isBefore(s.date)) latest[s.step] = s;
  }
  final done = {
    for (final step in PrepStep.values)
      if (latest[step] != null) step: latest[step]!,
  };
  DateTime plus(DateTime d, int days) {
    final day = farmDate(d);
    return DateTime(day.year, day.month, day.day + days);
  }

  final drain = done[PrepStep.drain], fill = done[PrepStep.fill];
  final furthest = done.keys
      .where((s) => s != PrepStep.rest)
      .fold<int>(-1, (m, s) => s.index > m ? s.index : m);
  return PrepProgress(
    done: done,
    next: PrepStep.values.where((s) => !done.containsKey(s)).firstOrNull,
    dryUntilMin: drain == null ? null : plus(drain.date, config.dryingDays.min),
    dryUntilMax: drain == null ? null : plus(drain.date, config.dryingDays.max),
    restUntil: fill == null ? null : plus(fill.date, config.restDays.min),
    canMarkReady: fill != null,
    skipped: [
      for (final s in PrepStep.values)
        if (s.index < furthest && !done.containsKey(s)) s,
    ],
    cycleStart: lastDayWithFish == null ? null : plus(lastDayWithFish, 1),
  );
}

/// The last farm day [pondId] held fish at the end of the day; null when it
/// never did.
DateTime? lastDayWithFish(FarmFacts f, String pondId) {
  DateTime? last;
  var had = false;
  for (final (day, placements) in dailyPlacements(f)) {
    final has = placements.any((p) => p.pondId == pondId && p.live.count > 0);
    if (has) {
      last = day;
    } else if (had) {
      last = DateTime(day.year, day.month, day.day - 1);
    }
    had = has;
  }
  return last;
}
