import 'types.dart';

/// Every farming number the app computes with or compares against.
/// Values and section references come from docs/DOMAIN.md; change both
/// together. Admins can override per site (later milestones).
class DomainConfig {
  const DomainConfig({
    required this.fryMaxG,
    required this.pregrowMaxG,
    required this.growoutMaxG,
    required this.rationRate,
    required this.maxRationRate,
    required this.leftoverReduction,
    required this.ateFastIncrease,
    required this.feedingGuides,
    required this.densityPerM2,
    required this.temperatureC,
    required this.ph,
    required this.minOxygenMgL,
    required this.waterRenewalPctPerWeek,
    required this.sampleIntervalDays,
    required this.sampleMinFish,
    required this.sampleMaxFish,
    required this.waterCheckIntervalDays,
    required this.fcrTarget,
    required this.feedAgeWarnDays,
    required this.feedAgeDangerDays,
    required this.lowStockDays,
    required this.mortalitySpikeShare,
    required this.mortalitySpikeMultiplier,
    required this.mortalityTrailingDays,
    required this.warningSignLookbackDays,
    required this.quarantineDays,
    required this.dryingDays,
    required this.restDays,
    required this.preHarvestFastHours,
    required this.limeKgPerM2,
    required this.manureKgPerM2,
    required this.pondSurfaceM2,
    required this.pondLengthWidthRatio,
    required this.minDepthM,
    required this.stockingWeightG,
    required this.acclimatisationMinutes,
  });

  static const defaults = DomainConfig(
    fryMaxG: 5,
    pregrowMaxG: 20,
    growoutMaxG: 250,
    rationRate: {
      Phase.fry: 0.05,
      Phase.pregrow: 0.05,
      Phase.growout: 0.04,
      Phase.finishing: 0.03,
    },
    maxRationRate: 0.05,
    leftoverReduction: 0.15,
    ateFastIncrease: 0.05,
    feedingGuides: {
      Phase.fry: FeedingGuide(
        proteinPct: Range(30, 35),
        pelletMinMm: 0.5,
        pelletMaxMm: 1.0,
        feedingsPerDay: Range(4, 6),
      ),
      Phase.pregrow: FeedingGuide(
        proteinPct: Range(25, 30),
        pelletMinMm: 2,
        pelletMaxMm: 2,
        feedingsPerDay: Range(4, 6),
      ),
      Phase.growout: FeedingGuide(
        proteinPct: Range(20, 25),
        pelletMinMm: 3,
        pelletMaxMm: 3,
        feedingsPerDay: Range(3, 4),
      ),
      Phase.finishing: FeedingGuide(
        pelletMinMm: 3,
        feedingsPerDay: Range(2, 3),
      ),
    },
    densityPerM2: {
      StructureType.earth: Range(2, 6),
      StructureType.tank: Range(50, 100),
      StructureType.cage: Range(150, 200),
    },
    temperatureC: Range(27, 32),
    ph: Range(6.5, 8.5),
    minOxygenMgL: 3.0,
    waterRenewalPctPerWeek: Range(10, 20),
    sampleIntervalDays: 14,
    sampleMinFish: 30,
    sampleMaxFish: 50,
    waterCheckIntervalDays: 7,
    fcrTarget: Range(1.5, 1.8),
    feedAgeWarnDays: 60,
    feedAgeDangerDays: 90,
    lowStockDays: 7,
    mortalitySpikeShare: 0.005,
    mortalitySpikeMultiplier: 3.0,
    mortalityTrailingDays: 7,
    warningSignLookbackDays: 3,
    quarantineDays: Range(7, 10),
    dryingDays: Range(5, 7),
    restDays: Range(2, 3),
    preHarvestFastHours: 48,
    limeKgPerM2: Range(0.1, 0.2),
    manureKgPerM2: Range(0.02, 0.03),
    pondSurfaceM2: Range(200, 1000),
    pondLengthWidthRatio: Range(2, 3),
    minDepthM: 1.0,
    stockingWeightG: Range(10, 20),
    acclimatisationMinutes: Range(15, 20),
  );

  /// Exclusive upper bounds of the fry, pregrow and growout phases, in grams.
  /// DOMAIN §Phases.
  final double fryMaxG;
  final double pregrowMaxG;
  final double growoutMaxG;

  /// Share of biomass fed per day, by phase. DOMAIN §Feeding [default].
  final Map<Phase, double> rationRate;

  /// Ceiling on the suggested ration (5 % of biomass). DOMAIN §Feeding.
  final double maxRationRate;

  /// Cut after leftovers, raise after fast eating. DOMAIN §Feeding [default].
  final double leftoverReduction;
  final double ateFastIncrease;

  /// Protein, pellet size and feedings per day. DOMAIN §Phases.
  final Map<Phase, FeedingGuide> feedingGuides;

  /// Fish per m² by structure. DOMAIN §Ponds.
  final Map<StructureType, Range<double>> densityPerM2;

  /// Water targets. DOMAIN §Water quality.
  final Range<double> temperatureC;
  final Range<double> ph;
  final double minOxygenMgL;
  final Range<int> waterRenewalPctPerWeek;

  /// DOMAIN §Sampling.
  final int sampleIntervalDays;
  final int sampleMinFish;
  final int sampleMaxFish;

  /// DOMAIN §Alert rules.
  final int waterCheckIntervalDays;

  /// DOMAIN §Formulas.
  final Range<double> fcrTarget;

  /// DOMAIN §Feed stock.
  final int feedAgeWarnDays;
  final int feedAgeDangerDays;
  final int lowStockDays;

  /// DOMAIN §Alert rules [default].
  final double mortalitySpikeShare;
  final double mortalitySpikeMultiplier;
  final int mortalityTrailingDays;
  final int warningSignLookbackDays;

  /// DOMAIN §Species and fingerlings, §Pond preparation.
  final Range<int> quarantineDays;
  final Range<int> dryingDays;
  final Range<int> restDays;

  /// DOMAIN §Harvest and delivery.
  final int preHarvestFastHours;

  /// Doses per m². DOMAIN §Formulas.
  final Range<double> limeKgPerM2;
  final Range<double> manureKgPerM2;

  /// Design guidance. DOMAIN §Ponds.
  final Range<double> pondSurfaceM2;
  final Range<double> pondLengthWidthRatio;
  final double minDepthM;

  /// DOMAIN §Species and fingerlings.
  final Range<int> stockingWeightG;
  final Range<int> acclimatisationMinutes;
}
