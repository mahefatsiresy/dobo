import 'dart:math';

import 'config.dart';
import 'types.dart';

/// Suggested feed for today, in grams. DOMAIN §Feeding.
int suggestedRationG({
  required int biomassG,
  required Phase phase,
  Leftover? lastLeftover,
  bool lastAteFast = false,
  required DomainConfig config,
}) {
  var rate = config.rationRate[phase]!;
  if (lastLeftover == Leftover.some || lastLeftover == Leftover.lots) {
    rate *= 1 - config.leftoverReduction;
  } else if (lastAteFast) {
    rate *= 1 + config.ateFastIncrease;
  }
  return (biomassG * min(rate, config.maxRationRate)).round();
}

/// Today's ration for a pond: [suggestedRationG] for each batch in it,
/// adjusted by the pond's last leftover report, added up.
int pondRationG({
  required List<({int biomassG, Phase phase})> batches,
  Leftover? lastLeftover,
  bool lastAteFast = false,
  required DomainConfig config,
}) => batches.fold(
  0,
  (sum, b) =>
      sum +
      suggestedRationG(
        biomassG: b.biomassG,
        phase: b.phase,
        lastLeftover: lastLeftover,
        lastAteFast: lastAteFast,
        config: config,
      ),
);
