import 'types.dart';

/// Every farming number the app computes with or compares against.
/// Values and section references come from docs/DOMAIN.md; change both
/// together. Admins can override per site (`config_overrides.dart`).
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
    required this.mortalitySpikeMinDeaths,
    required this.mortalityTrailingDays,
    required this.warningSignLookbackDays,
    required this.mortalityLookbackDays,
    required this.stopFeedingSignDays,
    required this.quarantineDays,
    required this.dryingDays,
    required this.restDays,
    required this.preHarvestFastHours,
    required this.harvestHour,
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
    mortalitySpikeMinDeaths: 5,
    mortalityTrailingDays: 7,
    warningSignLookbackDays: 3,
    mortalityLookbackDays: 3,
    stopFeedingSignDays: 2,
    quarantineDays: Range(7, 10),
    dryingDays: Range(5, 7),
    restDays: Range(2, 3),
    preHarvestFastHours: 48,
    harvestHour: 6,
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

  /// Fewer deaths than this in a day never count as a spike.
  final int mortalitySpikeMinDeaths;
  final int mortalityTrailingDays;
  final int warningSignLookbackDays;

  /// A mortality spike stays listed this many days. DOMAIN §Alert rules
  /// [default].
  final int mortalityLookbackDays;

  /// Surface or erratic swimming logged this many days back (today
  /// included) means "don't feed". DOMAIN §Feeding [default].
  final int stopFeedingSignDays;

  /// DOMAIN §Species and fingerlings, §Pond preparation.
  final Range<int> quarantineDays;
  final Range<int> dryingDays;
  final Range<int> restDays;

  /// DOMAIN §Harvest and delivery.
  final int preHarvestFastHours;

  /// Farm-clock hour a planned harvest starts ("early morning" [8.2]).
  /// DOMAIN §Harvest and delivery [default].
  final int harvestHour;

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

  /// This config with the given numbers replaced (admins' per-site
  /// overrides, SPEC F14).
  DomainConfig copyWith({
    double? fryMaxG,
    double? pregrowMaxG,
    double? growoutMaxG,
    Map<Phase, double>? rationRate,
    double? maxRationRate,
    double? leftoverReduction,
    double? ateFastIncrease,
    Map<Phase, FeedingGuide>? feedingGuides,
    Map<StructureType, Range<double>>? densityPerM2,
    Range<double>? temperatureC,
    Range<double>? ph,
    double? minOxygenMgL,
    Range<int>? waterRenewalPctPerWeek,
    int? sampleIntervalDays,
    int? sampleMinFish,
    int? sampleMaxFish,
    int? waterCheckIntervalDays,
    Range<double>? fcrTarget,
    int? feedAgeWarnDays,
    int? feedAgeDangerDays,
    int? lowStockDays,
    double? mortalitySpikeShare,
    double? mortalitySpikeMultiplier,
    int? mortalitySpikeMinDeaths,
    int? mortalityTrailingDays,
    int? warningSignLookbackDays,
    int? mortalityLookbackDays,
    int? stopFeedingSignDays,
    Range<int>? quarantineDays,
    Range<int>? dryingDays,
    Range<int>? restDays,
    int? preHarvestFastHours,
    int? harvestHour,
    Range<double>? limeKgPerM2,
    Range<double>? manureKgPerM2,
    Range<double>? pondSurfaceM2,
    Range<double>? pondLengthWidthRatio,
    double? minDepthM,
    Range<int>? stockingWeightG,
    Range<int>? acclimatisationMinutes,
  }) => DomainConfig(
    fryMaxG: fryMaxG ?? this.fryMaxG,
    pregrowMaxG: pregrowMaxG ?? this.pregrowMaxG,
    growoutMaxG: growoutMaxG ?? this.growoutMaxG,
    rationRate: rationRate ?? this.rationRate,
    maxRationRate: maxRationRate ?? this.maxRationRate,
    leftoverReduction: leftoverReduction ?? this.leftoverReduction,
    ateFastIncrease: ateFastIncrease ?? this.ateFastIncrease,
    feedingGuides: feedingGuides ?? this.feedingGuides,
    densityPerM2: densityPerM2 ?? this.densityPerM2,
    temperatureC: temperatureC ?? this.temperatureC,
    ph: ph ?? this.ph,
    minOxygenMgL: minOxygenMgL ?? this.minOxygenMgL,
    waterRenewalPctPerWeek:
        waterRenewalPctPerWeek ?? this.waterRenewalPctPerWeek,
    sampleIntervalDays: sampleIntervalDays ?? this.sampleIntervalDays,
    sampleMinFish: sampleMinFish ?? this.sampleMinFish,
    sampleMaxFish: sampleMaxFish ?? this.sampleMaxFish,
    waterCheckIntervalDays:
        waterCheckIntervalDays ?? this.waterCheckIntervalDays,
    fcrTarget: fcrTarget ?? this.fcrTarget,
    feedAgeWarnDays: feedAgeWarnDays ?? this.feedAgeWarnDays,
    feedAgeDangerDays: feedAgeDangerDays ?? this.feedAgeDangerDays,
    lowStockDays: lowStockDays ?? this.lowStockDays,
    mortalitySpikeShare: mortalitySpikeShare ?? this.mortalitySpikeShare,
    mortalitySpikeMultiplier:
        mortalitySpikeMultiplier ?? this.mortalitySpikeMultiplier,
    mortalitySpikeMinDeaths:
        mortalitySpikeMinDeaths ?? this.mortalitySpikeMinDeaths,
    mortalityTrailingDays: mortalityTrailingDays ?? this.mortalityTrailingDays,
    warningSignLookbackDays:
        warningSignLookbackDays ?? this.warningSignLookbackDays,
    mortalityLookbackDays: mortalityLookbackDays ?? this.mortalityLookbackDays,
    stopFeedingSignDays: stopFeedingSignDays ?? this.stopFeedingSignDays,
    quarantineDays: quarantineDays ?? this.quarantineDays,
    dryingDays: dryingDays ?? this.dryingDays,
    restDays: restDays ?? this.restDays,
    preHarvestFastHours: preHarvestFastHours ?? this.preHarvestFastHours,
    harvestHour: harvestHour ?? this.harvestHour,
    limeKgPerM2: limeKgPerM2 ?? this.limeKgPerM2,
    manureKgPerM2: manureKgPerM2 ?? this.manureKgPerM2,
    pondSurfaceM2: pondSurfaceM2 ?? this.pondSurfaceM2,
    pondLengthWidthRatio: pondLengthWidthRatio ?? this.pondLengthWidthRatio,
    minDepthM: minDepthM ?? this.minDepthM,
    stockingWeightG: stockingWeightG ?? this.stockingWeightG,
    acclimatisationMinutes:
        acclimatisationMinutes ?? this.acclimatisationMinutes,
  );
}
