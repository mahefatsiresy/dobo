/// Inclusive numeric range.
class Range<T extends num> {
  const Range(this.min, this.max);

  final T min;
  final T max;

  bool contains(num v) => v >= min && v <= max;
}

enum Phase { fry, pregrow, growout, finishing }

enum StructureType { earth, tank, cage }

enum PondRole { breeding, nursery, pregrow, growout, holding, quarantine }

enum WaterSupply { barrage, derivation, marsh }

enum WaterColour { clear, lightGreen, mediumGreen, darkGreen, brownTurbid }

enum WarningSign {
  noAppetite,
  surfaceSwimming,
  nearBanks,
  erraticOrCircling,
  abnormalColour,
  skinLesions,
  paleOrSwollenGills,
  groupedDeaths,
  rubbing,
  excessMucus,
  whiteSpots,
  bulgingEyes,
  finBleeding,
}

enum Leftover { none, some, lots }

enum ProductForm { live, fresh, frozen, smoked, dried }

enum PrepStep { drain, dry, treat, fertilise, fill, rest }

enum Severity { warning, danger }

class FeedingGuide {
  const FeedingGuide({
    this.proteinPct,
    required this.pelletMinMm,
    this.pelletMaxMm,
    required this.feedingsPerDay,
  });

  /// Null for finishing, which uses adult feed.
  final Range<double>? proteinPct;
  final double pelletMinMm;

  /// Null when there is no upper bound ("3 mm or more").
  final double? pelletMaxMm;
  final Range<int> feedingsPerDay;
}

enum PondStatus { empty, preparing, ready, stocked, isolated }

enum BatchStatus { quarantine, active, harvesting, closed }

/// Pond tags for worker screens and paper sheets: colours that stay distinct
/// on paper and in sunlight.
enum PondColour { blue, green, yellow, orange, red, purple, brown, black }

/// What a visit's condition check or observation is about (SPEC F5).
enum ObservationCategory {
  dike,
  inletScreen,
  predatorNets,
  fence,
  grass,
  predators,
  theft,
  other,
}

enum HealthAction { isolated, technicianCalled, released }

/// Signs seen on dead fish themselves (DOMAIN §Health, mortality handling).
const deathSigns = {
  WarningSign.skinLesions,
  WarningSign.paleOrSwollenGills,
  WarningSign.whiteSpots,
  WarningSign.bulgingEyes,
  WarningSign.finBleeding,
  WarningSign.abnormalColour,
};
