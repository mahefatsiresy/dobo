import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../domain/farm_facts.dart';
import '../../domain/growth.dart';
import '../common/farm_today.dart';
import 'pond_overview.dart';

/// Days of deaths the pond page charts.
const deathChartDays = 30;

/// How one batch grows in a pond (SPEC F6).
class BatchGrowth {
  const BatchGrowth({
    required this.batchId,
    required this.points,
    required this.periods,
    required this.trend,
    required this.survival,
    required this.daysSinceWeighing,
    required this.sampled,
  });

  final String batchId;
  final List<WeighPoint> points;
  final List<FcrPeriod> periods;
  final FcrTrend? trend;

  /// Over all the batch's ponds.
  final double? survival;

  /// Since the latest weighing point, never below 0 (a phone clock ahead).
  final int daysSinceWeighing;

  /// False while the only weight is the arrival's.
  final bool sampled;
}

class PondGrowth {
  const PondGrowth({
    required this.batches,
    required this.deathsPerDay,
    required this.deathsFrom,
  });

  final Map<String, BatchGrowth> batches;

  /// [deathChartDays] entries, the last one today.
  final List<int> deathsPerDay;
  final DateTime deathsFrom;
}

PondGrowth buildPondGrowth(
  FarmFacts f,
  String pondId,
  List<String> batchIds,
  DateTime today,
) {
  final from = DateTime(
    today.year,
    today.month,
    today.day - (deathChartDays - 1),
  );
  return PondGrowth(
    batches: {
      for (final id in batchIds)
        id: () {
          final points = weighPoints(f, batchId: id, pondId: pondId);
          final periods = fcrPeriods(f, batchId: id, pondId: pondId);
          return BatchGrowth(
            batchId: id,
            points: points,
            periods: periods,
            trend: fcrTrend(periods),
            survival: batchSurvival(f, id),
            daysSinceWeighing: points.isEmpty
                ? 0
                : max(0, daysBetween(points.last.date, today)),
            sampled: points.any((p) => p.fromSample),
          );
        }(),
    },
    deathsPerDay: dailyDeaths(f, pondId, from: from, to: today),
    deathsFrom: from,
  );
}

/// A pond's growth for its batches; null while loading.
final pondGrowthProvider = Provider.family<PondGrowth?, String>((ref, pondId) {
  final facts = ref.watch(farmFactsProvider).value;
  final overview = ref
      .watch(pondOverviewsProvider)
      .value
      ?.where((o) => o.pond.id == pondId)
      .firstOrNull;
  if (facts == null || overview == null) return null;
  return buildPondGrowth(facts, pondId, [
    for (final b in overview.batches) b.batch.id,
  ], ref.watch(farmTodayProvider));
});
