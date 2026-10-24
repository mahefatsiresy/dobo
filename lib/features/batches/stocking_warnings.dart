import '../../domain/config.dart';
import '../../domain/stock.dart';
import '../../domain/types.dart';
import '../ponds/pond_overview.dart';

/// Soft warnings when fish are put into a pond; none of them blocks.
enum StockingWarning {
  pondNotReady,
  pondIsolated,
  weightOutsideRange,
  densityBelow,
  densityAbove,
}

/// Density after adding [addedCount] fish to [target] (null without a
/// surface).
double? densityAfter(PondOverview target, int addedCount) => densityPerM2(
  live: target.liveCount + addedCount,
  surfaceM2: target.surfaceM2,
);

Set<StockingWarning> stockingWarnings({
  required PondOverview target,
  required int addedCount,
  double? avgWeightG,
  required DomainConfig config,
}) {
  final status = target.pond.status;
  final density = addedCount > 0 ? densityAfter(target, addedCount) : null;
  return {
    if (status == PondStatus.isolated)
      StockingWarning.pondIsolated
    else if (status != PondStatus.ready)
      StockingWarning.pondNotReady,
    if (avgWeightG != null && !config.stockingWeightG.contains(avgWeightG))
      StockingWarning.weightOutsideRange,
    ...switch (densityStatus(
      density: density,
      structure: target.pond.structure,
      config: config,
    )) {
      DensityStatus.below => {StockingWarning.densityBelow},
      DensityStatus.above => {StockingWarning.densityAbove},
      _ => const <StockingWarning>{},
    },
  };
}
