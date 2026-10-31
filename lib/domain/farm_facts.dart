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
/// [until]'s farm day count.
List<Placement> placementsOf(FarmFacts f, {DateTime? until}) {
  bool keep(DateTime d) => until == null || daysBetween(d, until) >= 0;
  return placements(
    stockings: [
      for (final s in f.stockings)
        if (keep(s.date)) s,
    ],
    transfers: [
      for (final t in f.transfers)
        if (keep(t.date)) t,
    ],
    samples: [
      for (final s in f.samples)
        if (keep(s.date)) s,
    ],
    deaths: [
      for (final l in f.logs)
        if (l.deaths > 0 && keep(l.date))
          DeathFact(pondId: l.pondId, count: l.deaths, date: l.date),
    ],
  );
}
