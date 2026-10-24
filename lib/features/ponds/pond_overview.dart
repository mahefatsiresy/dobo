import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../../domain/occupancy.dart';
import '../../domain/phase.dart';
import '../../domain/pond.dart';
import '../../domain/stock.dart';
import '../../domain/types.dart';

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
    required this.surfaceM2,
    required this.batches,
    required this.liveCount,
    required this.inconsistent,
    required this.biomassG,
    required this.density,
    required this.densityStatus,
  });

  final Pond pond;
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
}

PondOverview buildPondOverview(
  Pond pond,
  List<Placement> placements,
  Map<String, Batch> batches,
  DomainConfig config,
) {
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
  return PondOverview(
    pond: pond,
    surfaceM2: surface,
    batches: here,
    liveCount: live,
    inconsistent: here.any((b) => b.placement.live.inconsistent),
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

/// Every active pond with what it holds, by code.
final pondOverviewsProvider = Provider<AsyncValue<List<PondOverview>>>((ref) {
  final ponds = ref.watch(pondsProvider);
  final placements = ref.watch(placementsProvider);
  final summaries = ref.watch(batchSummariesProvider);
  if (!ponds.hasValue || !placements.hasValue || !summaries.hasValue) {
    return const AsyncLoading();
  }
  final batches = {for (final s in summaries.value!) s.batch.id: s.batch};
  return AsyncData([
    for (final p in ponds.value!)
      buildPondOverview(p, placements.value!, batches, DomainConfig.defaults),
  ]);
});
