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
  });

  final String id;
  final String pondId;
  final DateTime date;
  final int feedG;
  final int deaths;

  /// Warning signs and signs seen on dead fish.
  final Set<WarningSign> signs;
  final WaterColour? waterColour;
}

/// Every current record that moves fish, sets their weight or feeds them:
/// what growth, placements and alerts are computed from.
class FarmFacts {
  const FarmFacts({
    this.stockings = const [],
    this.transfers = const [],
    this.samples = const [],
    this.logs = const [],
  });

  const FarmFacts.empty() : this();

  final List<StockingFact> stockings;
  final List<TransferFact> transfers;
  final List<SampleFact> samples;
  final List<LogFact> logs;
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
      for (final l in f.logs)
        if (l.deaths > 0)
          DeathFact(pondId: l.pondId, count: l.deaths, date: l.date),
    ],
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
