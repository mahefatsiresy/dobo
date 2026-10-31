import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;

  test('defaults match DOMAIN.md for the most-edited values', () {
    expect(cfg.minOxygenMgL, 3.0);
    expect(cfg.rationRate[Phase.growout], 0.04);
    expect(cfg.densityPerM2[StructureType.earth]!.min, 2);
    expect(cfg.densityPerM2[StructureType.earth]!.max, 6);
    expect(cfg.sampleIntervalDays, 14);
    expect(cfg.feedingGuides[Phase.finishing]!.proteinPct, isNull);
  });

  test('M5 defaults: mortality window, stop-feeding signs, harvest hour', () {
    expect(cfg.mortalityLookbackDays, 3);
    expect(cfg.stopFeedingSignDays, 2);
    expect(cfg.harvestHour, 6);
  });

  test('every phase and structure type has a value', () {
    expect(Phase.values.every(cfg.rationRate.containsKey), isTrue);
    expect(Phase.values.every(cfg.feedingGuides.containsKey), isTrue);
    expect(StructureType.values.every(cfg.densityPerM2.containsKey), isTrue);
  });
}
