import 'dates.dart';
import 'stock.dart';

/// A batch put into a pond.
class StockingFact {
  const StockingFact({
    required this.batchId,
    required this.pondId,
    required this.count,
    required this.avgWeightG,
    required this.date,
  });

  final String batchId;
  final String pondId;
  final int count;
  final double avgWeightG;
  final DateTime date;
}

/// Fish of a batch moved between ponds. A null weight means "not weighed".
class TransferFact {
  const TransferFact({
    required this.batchId,
    required this.fromPondId,
    required this.toPondId,
    required this.count,
    this.avgWeightG,
    required this.date,
  });

  final String batchId;
  final String fromPondId;
  final String toPondId;
  final int count;
  final double? avgWeightG;
  final DateTime date;
}

/// A batch weighed in a pond: sets its average weight there.
class SampleFact {
  const SampleFact({
    required this.batchId,
    required this.pondId,
    required this.avgWeightG,
    required this.date,
  });

  final String batchId;
  final String pondId;
  final double avgWeightG;
  final DateTime date;
}

/// Deaths recorded for a pond on a day (daily logs are per pond).
class DeathFact {
  const DeathFact({
    required this.pondId,
    required this.count,
    required this.date,
  });

  final String pondId;
  final int count;
  final DateTime date;
}

/// The part of a batch in one pond.
class Placement {
  const Placement({
    required this.batchId,
    required this.pondId,
    required this.live,
    required this.avgWeightG,
  });

  final String batchId;
  final String pondId;

  /// Estimated, an upper bound (DOMAIN §Formulas).
  final LiveCount live;

  /// Weight of the most recent sample, stocking or move into this pond;
  /// null when none carried one.
  final double? avgWeightG;
}

/// Fish per (batch, pond) from stockings, moves, samples and deaths, one
/// entry per pair any fact touches. Facts are walked in date order; on the
/// same date stockings, then moves, then samples, then deaths, each in list
/// order. A pond's deaths are shared between its batches in proportion to
/// their fish at that moment; in a pond whose fish have gone they go to
/// the batch there most recently, and in a pond that never held fish they
/// are dropped. Harvests join in M7.
List<Placement> placements({
  required List<StockingFact> stockings,
  required List<TransferFact> transfers,
  List<SampleFact> samples = const [],
  List<DeathFact> deaths = const [],
}) => _walk(stockings, transfers, samples, deaths);

/// [placements] at the end of each farm day that has a fact, oldest first,
/// from a single walk: what "fish on day D" questions are answered from.
List<(DateTime, List<Placement>)> placementSnapshots({
  required List<StockingFact> stockings,
  required List<TransferFact> transfers,
  List<SampleFact> samples = const [],
  List<DeathFact> deaths = const [],
}) {
  final out = <(DateTime, List<Placement>)>[];
  _walk(stockings, transfers, samples, deaths, (day, p) => out.add((day, p)));
  return out;
}

List<Placement> _walk(
  List<StockingFact> stockings,
  List<TransferFact> transfers,
  List<SampleFact> samples,
  List<DeathFact> deaths, [
  void Function(DateTime day, List<Placement> placements)? onDayEnd,
]) {
  final pairs = <(String, String), _Pair>{};
  var clock = 0;
  _Pair touch(String batchId, String pondId) =>
      pairs.putIfAbsent((batchId, pondId), () => _Pair(batchId, pondId))
        ..touched = ++clock;

  final facts = <(DateTime, int, Object)>[
    for (final s in stockings) (s.date, 0, s),
    for (final t in transfers) (t.date, 1, t),
    for (final s in samples) (s.date, 2, s),
    for (final d in deaths) (d.date, 3, d),
  ];
  // Dart's List.sort isn't stable: break ties on the original position.
  final order = [for (var i = 0; i < facts.length; i++) i]
    ..sort((a, b) {
      final (da, ka, _) = facts[a];
      final (db, kb, _) = facts[b];
      final byDate = da.compareTo(db);
      if (byDate != 0) return byDate;
      return ka != kb ? ka.compareTo(kb) : a.compareTo(b);
    });

  List<Placement> snapshot() => [
    for (final p in pairs.values)
      Placement(
        batchId: p.batchId,
        pondId: p.pondId,
        live: liveCount(
          stocked: p.stocked,
          transferredIn: p.moved,
          transferredOut: p.out,
          deaths: p.deaths,
        ),
        avgWeightG: p.avgWeightG,
      ),
  ];

  DateTime? today;
  for (final i in order) {
    if (onDayEnd != null) {
      final day = farmDate(facts[i].$1);
      if (today != null && day != today) onDayEnd(today, snapshot());
      today = day;
    }
    switch (facts[i].$3) {
      case StockingFact s:
        touch(s.batchId, s.pondId)
          ..stocked += s.count
          ..avgWeightG = s.avgWeightG;
      case TransferFact t:
        final from = touch(t.batchId, t.fromPondId)..out += t.count;
        touch(t.batchId, t.toPondId)
          ..moved += t.count
          ..avgWeightG = t.avgWeightG ?? from.avgWeightG;
      case SampleFact s:
        touch(s.batchId, s.pondId).avgWeightG = s.avgWeightG;
      case DeathFact d:
        _shareDeaths(d, [
          for (final p in pairs.values)
            if (p.pondId == d.pondId) p,
        ]);
    }
  }

  if (onDayEnd != null && today != null) onDayEnd(today, snapshot());
  return snapshot();
}

void _shareDeaths(DeathFact d, List<_Pair> inPond) {
  if (inPond.isEmpty) return;
  final alive = [
    for (final p in inPond)
      if (p.running > 0) p,
  ];
  if (alive.isEmpty) {
    final latest = inPond.reduce((a, b) => a.touched >= b.touched ? a : b);
    latest.deaths += d.count;
    return;
  }
  final total = alive.fold(0, (n, p) => n + p.running);
  final shares = [
    for (final p in alive) (pair: p, exact: d.count * p.running / total),
  ];
  var left = d.count;
  for (final s in shares) {
    final whole = s.exact.floor();
    s.pair.deaths += whole;
    left -= whole;
  }
  shares.sort((a, b) {
    final byRemainder = (b.exact - b.exact.floor()).compareTo(
      a.exact - a.exact.floor(),
    );
    return byRemainder != 0
        ? byRemainder
        : a.pair.batchId.compareTo(b.pair.batchId);
  });
  for (final s in shares.take(left)) {
    s.pair.deaths += 1;
  }
}

class _Pair {
  _Pair(this.batchId, this.pondId);

  final String batchId;
  final String pondId;
  int stocked = 0;
  int moved = 0;
  int out = 0;
  int deaths = 0;
  double? avgWeightG;

  /// Order of the last fact that touched this pair.
  int touched = 0;

  int get running => stocked + moved - out - deaths;
}
