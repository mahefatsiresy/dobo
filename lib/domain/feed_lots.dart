import 'config.dart';
import 'dates.dart';
import 'farm_facts.dart';
import 'feed_stock.dart';
import 'occupancy.dart';
import 'phase.dart';
import 'types.dart';

/// A feed delivery, which is a lot (SPEC F11).
class FeedLotFact {
  const FeedLotFact({
    required this.id,
    required this.phase,
    required this.weightG,
    required this.manufacturedOn,
    required this.deliveredOn,
    this.label,
  });

  final String id;

  /// The phase the feed is made for.
  final Phase phase;
  final int weightG;
  final DateTime manufacturedOn;
  final DateTime deliveredOn;
  final String? label;
}

class FeedDiscardFact {
  const FeedDiscardFact({
    required this.lotId,
    required this.weightG,
    required this.date,
  });

  final String lotId;
  final int weightG;
  final DateTime date;
}

class FeedLotBalance {
  const FeedLotBalance(this.lot, this.balanceG, this.age);

  final FeedLotFact lot;

  /// Delivered − discarded − drawn, never below 0.
  final int balanceG;
  final FeedAge age;
}

/// Feed on hand, derived from deliveries, discards and daily logs.
class FeedStock {
  const FeedStock({
    required this.lots,
    required this.onHandG,
    required this.expiredG,
    required this.overdrawnG,
    required this.dailyUsageG,
    required this.daysLeft,
  });

  /// Every lot, oldest first.
  final List<FeedLotBalance> lots;

  /// Balance of the lots still fit to use.
  final int onHandG;

  /// Balance of the lots past "do not use".
  final int expiredG;

  /// Feed logged beyond what the lots held: never a negative balance.
  final int overdrawnG;
  final int dailyUsageG;

  /// Null when no feed was logged lately.
  final double? daysLeft;
}

int _oldestFirst(FeedLotFact a, FeedLotFact b) {
  final made = a.manufacturedOn.compareTo(b.manufacturedOn);
  if (made != 0) return made;
  final delivered = a.deliveredOn.compareTo(b.deliveredOn);
  return delivered != 0 ? delivered : a.id.compareTo(b.id);
}

/// Each lot's balance and the farm's stock on [today] (plan M7 Decisions
/// 5–7). [countedLogs] are oldest first, one per pond-day. A log with a
/// known lot draws from it; a log without draws from the oldest lot
/// delivered by its day that still holds feed. Logs before the first
/// delivery draw nothing.
FeedStock feedStock({
  required List<FeedLotFact> lots,
  required List<FeedDiscardFact> discards,
  required List<LogFact> countedLogs,
  required DateTime today,
  required DomainConfig config,
}) {
  final ordered = [...lots]..sort(_oldestFirst);
  final left = {for (final l in ordered) l.id: l.weightG};
  var overdrawn = 0;

  void take(String lotId, int g) {
    final have = left[lotId]!;
    final used = g < have ? g : have;
    left[lotId] = have - used;
    overdrawn += g - used;
  }

  for (final d in discards) {
    if (left.containsKey(d.lotId)) take(d.lotId, d.weightG);
  }

  final firstDelivery = ordered.isEmpty
      ? null
      : ordered
            .map((l) => farmDayNumber(l.deliveredOn))
            .reduce((a, b) => a < b ? a : b);
  final deliveredDay = {
    for (final l in ordered) l.id: farmDayNumber(l.deliveredOn),
  };
  for (final log in countedLogs) {
    if (log.feedG <= 0) continue;
    final day = farmDayNumber(log.date);
    // A lot can't feed a day before it arrived: such a stamp (a sheet
    // transcribed late, a pre-M7 log corrected) draws as unstamped.
    final stamped = deliveredDay[log.feedLotId];
    if (stamped != null && stamped <= day) {
      take(log.feedLotId!, log.feedG);
      continue;
    }
    if (firstDelivery == null || day < firstDelivery) continue;
    var need = log.feedG;
    for (final l in ordered) {
      if (need == 0) break;
      if (farmDayNumber(l.deliveredOn) > day || left[l.id]! == 0) continue;
      final used = need < left[l.id]! ? need : left[l.id]!;
      left[l.id] = left[l.id]! - used;
      need -= used;
    }
    overdrawn += need;
  }

  final balances = [
    for (final l in ordered)
      FeedLotBalance(
        l,
        left[l.id]!,
        feedLotAge(
          manufacturedOn: l.manufacturedOn,
          today: today,
          config: config,
        ),
      ),
  ];
  var onHand = 0, expired = 0;
  for (final b in balances) {
    if (b.age == FeedAge.expired) {
      expired += b.balanceG;
    } else {
      onHand += b.balanceG;
    }
  }

  final todayN = farmDayNumber(today);
  var recent = 0;
  for (final log in countedLogs) {
    final back = todayN - farmDayNumber(log.date);
    if (back >= 0 && back < config.feedUsageDays) recent += log.feedG;
  }
  final usage = (recent / config.feedUsageDays).round();

  return FeedStock(
    lots: balances,
    onHandG: onHand,
    expiredG: expired,
    overdrawnG: overdrawn,
    dailyUsageG: usage,
    daysLeft: daysOfStockLeft(stockG: onHand, dailyUsageG: usage),
  );
}

/// The lot a log of [day] for a pond in [pondPhase] draws from: the oldest
/// usable lot of that phase, else the oldest usable lot. Usable: delivered
/// by [day], fit to use and holding feed.
String? defaultFeedLot({
  required FeedStock stock,
  required Phase? pondPhase,
  required DateTime day,
}) {
  final usable = [for (final b in usableLots(stock, day)) b.lot];
  for (final l in usable) {
    if (l.phase == pondPhase) return l.id;
  }
  return usable.isEmpty ? null : usable.first.id;
}

/// The phase of the batch with the most biomass in [pondId]; null when the
/// pond holds no weighed fish.
Phase? pondPhase(
  List<Placement> placements,
  String pondId,
  DomainConfig config,
) {
  Placement? best;
  var bestG = 0.0;
  for (final p in placements) {
    if (p.pondId != pondId || p.live.count <= 0 || p.avgWeightG == null) {
      continue;
    }
    final g = p.live.count * p.avgWeightG!;
    if (best == null || g > bestG) {
      best = p;
      bestG = g;
    }
  }
  return best == null ? null : phaseFor(best.avgWeightG!, config);
}

/// Lots a log of [day] may draw from: delivered by then, not past "do not
/// use", still holding feed. Oldest first.
List<FeedLotBalance> usableLots(FeedStock stock, DateTime day) => [
  for (final b in stock.lots)
    if (b.age != FeedAge.expired &&
        b.balanceG > 0 &&
        daysBetween(b.lot.deliveredOn, day) >= 0)
      b,
];
