import 'config.dart';
import 'types.dart';

/// Growth phase from average weight; a weight on a boundary belongs to the
/// heavier phase. DOMAIN §Phases.
Phase phaseFor(double avgWeightG, DomainConfig config) {
  if (avgWeightG < config.fryMaxG) return Phase.fry;
  if (avgWeightG < config.pregrowMaxG) return Phase.pregrow;
  if (avgWeightG < config.growoutMaxG) return Phase.growout;
  return Phase.finishing;
}

FeedingGuide feedingGuideFor(Phase phase, DomainConfig config) =>
    config.feedingGuides[phase]!;
