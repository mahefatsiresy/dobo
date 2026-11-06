import 'dates.dart';
import 'occupancy.dart';
import 'types.dart';

/// One pond-day from a daily log.
class LogFact {
  const LogFact({
    required this.id,
    required this.pondId,
    required this.date,
    this.feedG = 0,
    this.deaths = 0,
    this.signs = const {},
    this.waterColour,
    this.enteredBy = '',
    this.observedBy,
    this.feedLotId,
  });

  final String id;
  final String pondId;
  final DateTime date;
  final int feedG;
  final int deaths;

  /// Warning signs and signs seen on dead fish.
  final Set<WarningSign> signs;
  final WaterColour? waterColour;

  /// The account that entered it.
  final String enteredBy;

  /// The person who saw it, when not the one entering (CLAUDE.md "Who").
  final String? observedBy;

  /// The feed lot the feed came from; null when none was stamped.
  final String? feedLotId;
}

/// Every current record that moves fish, sets their weight or feeds them:
/// what growth, placements and alerts are computed from.
class FarmFacts {
  const FarmFacts({
    this.stockings = const [],
    this.transfers = const [],
    this.samples = const [],
    this.logs = const [],
    this.harvests = const [],
  });

  const FarmFacts.empty() : this();

  final List<StockingFact> stockings;
  final List<TransferFact> transfers;
  final List<SampleFact> samples;
  final List<LogFact> logs;
  final List<HarvestFact> harvests;
}

/// [placements] from [f]. With [until], only facts dated on or before
/// [until]'s farm day count. Answered from one walk per [FarmFacts], kept
/// with it: growth and alerts ask this for many days.
List<Placement> placementsOf(FarmFacts f, {DateTime? until}) {
  final days = _timelines[f] ??= placementSnapshots(
    stockings: f.stockings,
    transfers: f.transfers,
    samples: f.samples,
    deaths: [
      for (final l in countedLogs(f))
        if (l.deaths > 0)
          DeathFact(pondId: l.pondId, count: l.deaths, date: l.date),
    ],
    harvests: f.harvests,
  );
  if (days.isEmpty) return const [];
  if (until == null) return days.last.$2;
  // The last day on or before [until].
  var lo = 0, hi = days.length - 1, found = -1;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    if (daysBetween(days[mid].$1, until) >= 0) {
      found = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return found < 0 ? const [] : days[found].$2;
}

/// Each [FarmFacts]' placements at the end of each farm day with a fact.
final _timelines = Expando<List<(DateTime, List<Placement>)>>();

/// The logs that count in numbers (deaths, feed): one per pond-day, the
/// newest, as the daily log screen shows it. Two phones logging the same
/// day must not double it before a member resolves the duplicate (SPEC
/// §7); signs and duplicate checks still read every log in [FarmFacts.logs].
List<LogFact> countedLogs(FarmFacts f) => _counted[f] ??= () {
  // Logs come oldest first, so the last one of a pond-day is the newest.
  final byDay = <(String, int), LogFact>{};
  for (final l in f.logs) {
    byDay[(l.pondId, farmDayNumber(l.date))] = l;
  }
  return [
    for (final l in f.logs)
      if (identical(byDay[(l.pondId, farmDayNumber(l.date))], l)) l,
  ];
}();

final _counted = Expando<List<LogFact>>();
