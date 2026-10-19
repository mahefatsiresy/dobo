import 'config.dart';
import 'types.dart';

/// Estimated fish alive. Predation and theft are invisible to it, so it is an
/// upper bound. [inconsistent] means the records subtract to below zero.
class LiveCount {
  const LiveCount(this.count, {required this.inconsistent});

  final int count;
  final bool inconsistent;
}

LiveCount liveCount({
  required int stocked,
  int transferredIn = 0,
  int transferredOut = 0,
  int deaths = 0,
  int harvested = 0,
}) {
  final n = stocked + transferredIn - transferredOut - deaths - harvested;
  return n < 0
      ? const LiveCount(0, inconsistent: true)
      : LiveCount(n, inconsistent: false);
}

class SampleResult {
  const SampleResult(this.avgWeightG, {required this.smallSample});

  final double avgWeightG;
  final bool smallSample;
}

/// Average weight of a weighed sample; null when nothing was weighed.
SampleResult? sampleResult({
  required int fishCount,
  required int totalWeightG,
  required DomainConfig config,
}) {
  if (fishCount <= 0 || totalWeightG <= 0) return null;
  return SampleResult(totalWeightG / fishCount,
      smallSample: fishCount < config.sampleMinFish);
}

int biomassG({required int liveCount, required double avgWeightG}) =>
    (liveCount * avgWeightG).round();

double? survivalRate({required int live, required int entered}) =>
    entered <= 0 ? null : live / entered;

double? densityPerM2({required int live, required double? surfaceM2}) =>
    surfaceM2 == null || surfaceM2 <= 0 ? null : live / surfaceM2;

enum DensityStatus { below, within, above }

DensityStatus? densityStatus({
  required double? density,
  required StructureType structure,
  required DomainConfig config,
}) {
  if (density == null) return null;
  final range = config.densityPerM2[structure]!;
  if (density < range.min) return DensityStatus.below;
  if (density > range.max) return DensityStatus.above;
  return DensityStatus.within;
}
