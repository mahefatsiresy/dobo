import 'config.dart';
import 'types.dart';

/// One farming number an admin may override for a site (SPEC F14). Range
/// bounds are `<field>.min` and `<field>.max`; per-phase or per-structure
/// values are `<field>.<name>`.
class ConfigKey {
  const ConfigKey(
    this.key,
    this.section,
    this.read,
    this.write, {
    this.isInt = false,
  });

  final String key;

  /// The DOMAIN.md section the default comes from, e.g. `§Water quality`.
  final String section;
  final num Function(DomainConfig) read;
  final DomainConfig Function(DomainConfig, num) write;
  final bool isInt;

  /// The key without its `.min` / `.max`: what the number is about.
  String get subject => key.endsWith('.min') || key.endsWith('.max')
      ? key.substring(0, key.length - 4)
      : key;
}

/// Keys for both bounds of a range field.
List<ConfigKey> _range<T extends num>(
  String key,
  String section,
  Range<T> Function(DomainConfig) get,
  DomainConfig Function(DomainConfig, Range<T>) set, {
  bool isInt = false,
}) {
  T cast(num v) => (isInt ? v.round() : v.toDouble()) as T;
  return [
    ConfigKey(
      '$key.min',
      section,
      (c) => get(c).min,
      (c, v) => set(c, Range<T>(cast(v), get(c).max)),
      isInt: isInt,
    ),
    ConfigKey(
      '$key.max',
      section,
      (c) => get(c).max,
      (c, v) => set(c, Range<T>(get(c).min, cast(v))),
      isInt: isInt,
    ),
  ];
}

ConfigKey _int(
  String key,
  String section,
  int Function(DomainConfig) get,
  DomainConfig Function(DomainConfig, int) set,
) => ConfigKey(key, section, get, (c, v) => set(c, v.round()), isInt: true);

ConfigKey _double(
  String key,
  String section,
  double Function(DomainConfig) get,
  DomainConfig Function(DomainConfig, double) set,
) => ConfigKey(key, section, get, (c, v) => set(c, v.toDouble()));

/// Every numeric field of [DomainConfig] (feeding guides excepted: they
/// are text guidance), in DOMAIN.md order.
final List<ConfigKey> configKeys = [
  _double(
    'fryMaxG',
    '§Phases',
    (c) => c.fryMaxG,
    (c, v) => c.copyWith(fryMaxG: v),
  ),
  _double(
    'pregrowMaxG',
    '§Phases',
    (c) => c.pregrowMaxG,
    (c, v) => c.copyWith(pregrowMaxG: v),
  ),
  _double(
    'growoutMaxG',
    '§Phases',
    (c) => c.growoutMaxG,
    (c, v) => c.copyWith(growoutMaxG: v),
  ),
  for (final phase in Phase.values)
    _double(
      'rationRate.${phase.name}',
      '§Feeding',
      (c) => c.rationRate[phase]!,
      (c, v) => c.copyWith(rationRate: {...c.rationRate, phase: v}),
    ),
  _double(
    'maxRationRate',
    '§Feeding',
    (c) => c.maxRationRate,
    (c, v) => c.copyWith(maxRationRate: v),
  ),
  _double(
    'leftoverReduction',
    '§Feeding',
    (c) => c.leftoverReduction,
    (c, v) => c.copyWith(leftoverReduction: v),
  ),
  _double(
    'ateFastIncrease',
    '§Feeding',
    (c) => c.ateFastIncrease,
    (c, v) => c.copyWith(ateFastIncrease: v),
  ),
  for (final s in StructureType.values)
    ..._range<double>(
      'densityPerM2.${s.name}',
      '§Ponds',
      (c) => c.densityPerM2[s]!,
      (c, r) => c.copyWith(densityPerM2: {...c.densityPerM2, s: r}),
    ),
  ..._range<double>(
    'temperatureC',
    '§Water quality',
    (c) => c.temperatureC,
    (c, r) => c.copyWith(temperatureC: r),
  ),
  ..._range<double>(
    'ph',
    '§Water quality',
    (c) => c.ph,
    (c, r) => c.copyWith(ph: r),
  ),
  _double(
    'minOxygenMgL',
    '§Water quality',
    (c) => c.minOxygenMgL,
    (c, v) => c.copyWith(minOxygenMgL: v),
  ),
  ..._range<int>(
    'waterRenewalPctPerWeek',
    '§Water quality',
    (c) => c.waterRenewalPctPerWeek,
    (c, r) => c.copyWith(waterRenewalPctPerWeek: r),
    isInt: true,
  ),
  _int(
    'sampleIntervalDays',
    '§Sampling',
    (c) => c.sampleIntervalDays,
    (c, v) => c.copyWith(sampleIntervalDays: v),
  ),
  _int(
    'sampleMinFish',
    '§Sampling',
    (c) => c.sampleMinFish,
    (c, v) => c.copyWith(sampleMinFish: v),
  ),
  _int(
    'sampleMaxFish',
    '§Sampling',
    (c) => c.sampleMaxFish,
    (c, v) => c.copyWith(sampleMaxFish: v),
  ),
  _int(
    'waterCheckIntervalDays',
    '§Alert rules',
    (c) => c.waterCheckIntervalDays,
    (c, v) => c.copyWith(waterCheckIntervalDays: v),
  ),
  ..._range<double>(
    'fcrTarget',
    '§Formulas',
    (c) => c.fcrTarget,
    (c, r) => c.copyWith(fcrTarget: r),
  ),
  _int(
    'feedAgeWarnDays',
    '§Feed stock',
    (c) => c.feedAgeWarnDays,
    (c, v) => c.copyWith(feedAgeWarnDays: v),
  ),
  _int(
    'feedAgeDangerDays',
    '§Feed stock',
    (c) => c.feedAgeDangerDays,
    (c, v) => c.copyWith(feedAgeDangerDays: v),
  ),
  _int(
    'lowStockDays',
    '§Feed stock',
    (c) => c.lowStockDays,
    (c, v) => c.copyWith(lowStockDays: v),
  ),
  _double(
    'mortalitySpikeShare',
    '§Alert rules',
    (c) => c.mortalitySpikeShare,
    (c, v) => c.copyWith(mortalitySpikeShare: v),
  ),
  _double(
    'mortalitySpikeMultiplier',
    '§Alert rules',
    (c) => c.mortalitySpikeMultiplier,
    (c, v) => c.copyWith(mortalitySpikeMultiplier: v),
  ),
  _int(
    'mortalitySpikeMinDeaths',
    '§Alert rules',
    (c) => c.mortalitySpikeMinDeaths,
    (c, v) => c.copyWith(mortalitySpikeMinDeaths: v),
  ),
  _int(
    'mortalityTrailingDays',
    '§Alert rules',
    (c) => c.mortalityTrailingDays,
    (c, v) => c.copyWith(mortalityTrailingDays: v),
  ),
  _int(
    'warningSignLookbackDays',
    '§Alert rules',
    (c) => c.warningSignLookbackDays,
    (c, v) => c.copyWith(warningSignLookbackDays: v),
  ),
  _int(
    'mortalityLookbackDays',
    '§Alert rules',
    (c) => c.mortalityLookbackDays,
    (c, v) => c.copyWith(mortalityLookbackDays: v),
  ),
  _int(
    'stopFeedingSignDays',
    '§Feeding',
    (c) => c.stopFeedingSignDays,
    (c, v) => c.copyWith(stopFeedingSignDays: v),
  ),
  ..._range<int>(
    'quarantineDays',
    '§Species and fingerlings',
    (c) => c.quarantineDays,
    (c, r) => c.copyWith(quarantineDays: r),
    isInt: true,
  ),
  ..._range<int>(
    'dryingDays',
    '§Pond preparation',
    (c) => c.dryingDays,
    (c, r) => c.copyWith(dryingDays: r),
    isInt: true,
  ),
  ..._range<int>(
    'restDays',
    '§Pond preparation',
    (c) => c.restDays,
    (c, r) => c.copyWith(restDays: r),
    isInt: true,
  ),
  _int(
    'preHarvestFastHours',
    '§Harvest and delivery',
    (c) => c.preHarvestFastHours,
    (c, v) => c.copyWith(preHarvestFastHours: v),
  ),
  _int(
    'harvestHour',
    '§Harvest and delivery',
    (c) => c.harvestHour,
    (c, v) => c.copyWith(harvestHour: v),
  ),
  ..._range<double>(
    'limeKgPerM2',
    '§Formulas',
    (c) => c.limeKgPerM2,
    (c, r) => c.copyWith(limeKgPerM2: r),
  ),
  ..._range<double>(
    'manureKgPerM2',
    '§Formulas',
    (c) => c.manureKgPerM2,
    (c, r) => c.copyWith(manureKgPerM2: r),
  ),
  ..._range<double>(
    'pondSurfaceM2',
    '§Ponds',
    (c) => c.pondSurfaceM2,
    (c, r) => c.copyWith(pondSurfaceM2: r),
  ),
  ..._range<double>(
    'pondLengthWidthRatio',
    '§Ponds',
    (c) => c.pondLengthWidthRatio,
    (c, r) => c.copyWith(pondLengthWidthRatio: r),
  ),
  _double(
    'minDepthM',
    '§Ponds',
    (c) => c.minDepthM,
    (c, v) => c.copyWith(minDepthM: v),
  ),
  ..._range<int>(
    'stockingWeightG',
    '§Species and fingerlings',
    (c) => c.stockingWeightG,
    (c, r) => c.copyWith(stockingWeightG: r),
    isInt: true,
  ),
  ..._range<int>(
    'acclimatisationMinutes',
    '§Species and fingerlings',
    (c) => c.acclimatisationMinutes,
    (c, r) => c.copyWith(acclimatisationMinutes: r),
    isInt: true,
  ),
];

final _byKey = {for (final k in configKeys) k.key: k};

/// [base] with an admin's [overrides] (SPEC F14). Unknown keys, negative
/// values, and values that would leave a range upside down (or the phases
/// out of order) are ignored. Overrides are retried until none more apply,
/// so a range moved as a whole works whichever bound comes first.
DomainConfig applyOverrides(DomainConfig base, Map<String, num> overrides) {
  var config = base;
  final pending = {
    for (final e in overrides.entries)
      if (_byKey.containsKey(e.key) && e.value >= 0) e.key: e.value,
  };
  var progress = true;
  while (progress && pending.isNotEmpty) {
    progress = false;
    for (final key in [...pending.keys]) {
      final next = _byKey[key]!.write(config, pending[key]!);
      if (_sane(next)) {
        config = next;
        pending.remove(key);
        progress = true;
      }
    }
  }
  return config;
}

bool _sane(DomainConfig c) {
  bool ordered(Range<num> r) => r.min <= r.max;
  return c.fryMaxG < c.pregrowMaxG &&
      c.pregrowMaxG < c.growoutMaxG &&
      c.sampleMinFish <= c.sampleMaxFish &&
      c.feedAgeWarnDays <= c.feedAgeDangerDays &&
      c.harvestHour <= 23 &&
      [
        ...c.densityPerM2.values,
        c.temperatureC,
        c.ph,
        c.waterRenewalPctPerWeek,
        c.fcrTarget,
        c.quarantineDays,
        c.dryingDays,
        c.restDays,
        c.limeKgPerM2,
        c.manureKgPerM2,
        c.pondSurfaceM2,
        c.pondLengthWidthRatio,
        c.stockingWeightG,
        c.acclimatisationMinutes,
      ].every(ordered);
}
