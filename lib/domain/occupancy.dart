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

  /// Weight of the most recent stocking or move into this pond; null when
  /// none carried one.
  final double? avgWeightG;
}

/// Fish per (batch, pond) from stockings and moves, one entry per pair any
/// fact touches. Deaths and harvests join in later milestones.
List<Placement> placements({
  required List<StockingFact> stockings,
  required List<TransferFact> transfers,
}) {
  final pairs = <(String, String), _Pair>{};
  _Pair pair(String batchId, String pondId) =>
      pairs.putIfAbsent((batchId, pondId), _Pair.new);

  // Date order; on the same date, stockings before moves, then list order.
  final facts =
      <(DateTime, int, Object)>[
        for (final (i, s) in stockings.indexed) (s.date, i, s),
        for (final (i, t) in transfers.indexed)
          (t.date, stockings.length + i, t),
      ]..sort((a, b) {
        final byDate = a.$1.compareTo(b.$1);
        return byDate != 0 ? byDate : a.$2.compareTo(b.$2);
      });

  for (final (_, _, fact) in facts) {
    switch (fact) {
      case StockingFact s:
        pair(s.batchId, s.pondId)
          ..stocked += s.count
          ..avgWeightG = s.avgWeightG;
      case TransferFact t:
        final from = pair(t.batchId, t.fromPondId)..out += t.count;
        pair(t.batchId, t.toPondId)
          ..moved += t.count
          ..avgWeightG = t.avgWeightG ?? from.avgWeightG;
    }
  }

  return [
    for (final MapEntry(key: (batchId, pondId), value: p) in pairs.entries)
      Placement(
        batchId: batchId,
        pondId: pondId,
        live: liveCount(
          stocked: p.stocked,
          transferredIn: p.moved,
          transferredOut: p.out,
        ),
        avgWeightG: p.avgWeightG,
      ),
  ];
}

class _Pair {
  int stocked = 0;
  int moved = 0;
  int out = 0;
  double? avgWeightG;
}
