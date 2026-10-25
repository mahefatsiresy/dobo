import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../../domain/dates.dart';
import '../../domain/occupancy.dart';
import '../../domain/phase.dart';
import '../../domain/pond.dart';
import '../../domain/ration.dart';
import '../../domain/stock.dart';
import '../../domain/types.dart';
import '../common/farm_today.dart';

/// One batch's share of a pond.
class BatchInPond {
  const BatchInPond({
    required this.batch,
    required this.placement,
    required this.phase,
    required this.biomassG,
  });

  final Batch batch;
  final Placement placement;

  /// Null while no weight is known.
  final Phase? phase;
  final int? biomassG;
}

/// What a pond holds, all estimated (DOMAIN §Formulas).
class PondOverview {
  const PondOverview({
    required this.pond,
    required this.status,
    required this.surfaceM2,
    required this.batches,
    required this.liveCount,
    required this.inconsistent,
    required this.biomassG,
    required this.density,
    required this.densityStatus,
    required this.rationG,
  });

  final Pond pond;

  /// What screens show: fish decide stocked/empty (see
  /// [effectivePondStatus]).
  final PondStatus status;
  final double? surfaceM2;
  final List<BatchInPond> batches;
  final int liveCount;

  /// The records subtract to below zero for some batch here.
  final bool inconsistent;

  /// Null when a batch in the pond has no known weight.
  final int? biomassG;
  final double? density;

  /// Null when the pond has no fish or no surface.
  final DensityStatus? densityStatus;

  /// Today's suggested feed in grams over the batches with a known weight,
  /// after the last day's leftovers; 0 without fish.
  final int rationG;
}

PondOverview buildPondOverview(
  Pond pond,
  List<Placement> placements,
  Map<String, Batch> batches,
  DomainConfig config, {
  Leftover? lastLeftover,
  bool lastAteFast = false,
}) {
  final here = [
    for (final p in placements)
      if (p.pondId == pond.id &&
          (p.live.count > 0 || p.live.inconsistent) &&
          batches.containsKey(p.batchId))
        BatchInPond(
          batch: batches[p.batchId]!,
          placement: p,
          phase: p.avgWeightG == null ? null : phaseFor(p.avgWeightG!, config),
          biomassG: p.avgWeightG == null
              ? null
              : biomassG(liveCount: p.live.count, avgWeightG: p.avgWeightG!),
        ),
  ];
  final surface = pondSurfaceM2(
    lengthM: pond.lengthM,
    widthM: pond.widthM,
    overrideM2: pond.surfaceM2Override,
  );
  final live = here.fold(0, (n, b) => n + b.placement.live.count);
  final density = densityPerM2(live: live, surfaceM2: surface);
  final inconsistent = here.any((b) => b.placement.live.inconsistent);
  return PondOverview(
    pond: pond,
    status: effectivePondStatus(
      stored: pond.status,
      liveCount: live,
      inconsistent: inconsistent,
    ),
    surfaceM2: surface,
    batches: here,
    liveCount: live,
    inconsistent: inconsistent,
    biomassG: here.any((b) => b.biomassG == null)
        ? null
        : here.fold<int>(0, (n, b) => n + b.biomassG!),
    density: density,
    densityStatus: live == 0
        ? null
        : densityStatus(
            density: density,
            structure: pond.structure,
            config: config,
          ),
    rationG: pondRationG(
      batches: [
        for (final b in here)
          if (b.biomassG != null && b.phase != null)
            (biomassG: b.biomassG!, phase: b.phase!),
      ],
      lastLeftover: lastLeftover,
      lastAteFast: lastAteFast,
      config: config,
    ),
  );
}

final pondsProvider = StreamProvider<List<Pond>>(
  (ref) => ref.watch(pondRepositoryProvider).watchActive(),
);

final placementsProvider = StreamProvider<List<Placement>>(
  (ref) => ref.watch(batchRepositoryProvider).watchPlacements(),
);

final batchSummariesProvider = StreamProvider<List<BatchSummary>>(
  (ref) => ref.watch(batchRepositoryProvider).watchAll(),
);

/// Today in Madagascar.
DateTime farmToday() => farmDate(DateTime.now().toUtc());

/// Each pond's last daily log before today.
final lastLogsProvider = StreamProvider<Map<String, DailyLog>>(
  (ref) => ref
      .watch(dailyLogRepositoryProvider)
      .watchLatestBefore(ref.watch(farmTodayProvider)),
);

/// Every active pond with what it holds, by code.
final pondOverviewsProvider = Provider<AsyncValue<List<PondOverview>>>((ref) {
  final ponds = ref.watch(pondsProvider);
  final placements = ref.watch(placementsProvider);
  final summaries = ref.watch(batchSummariesProvider);
  if (!ponds.hasValue || !placements.hasValue || !summaries.hasValue) {
    return const AsyncLoading();
  }
  final batches = {for (final s in summaries.value!) s.batch.id: s.batch};
  final lastLogs = ref.watch(lastLogsProvider).value ?? const {};
  return AsyncData([
    for (final p in ponds.value!)
      buildPondOverview(
        p,
        placements.value!,
        batches,
        DomainConfig.defaults,
        lastLeftover: lastLogs[p.id]?.leftover,
        lastAteFast: lastLogs[p.id]?.ateFast ?? false,
      ),
  ]);
});
