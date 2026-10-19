import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/stock.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;

  group('liveCount', () {
    test('subtracts deaths, transfers out and harvests; adds transfers in', () {
      expect(liveCount(stocked: 1000, deaths: 50).count, 950);
      expect(liveCount(stocked: 1000, deaths: 50).inconsistent, isFalse);
      expect(
        liveCount(
          stocked: 1000,
          transferredIn: 200,
          transferredOut: 300,
          deaths: 50,
          harvested: 100,
        ).count,
        750,
      );
    });

    test('more deaths than fish clamps to 0 and flags inconsistent', () {
      final bad = liveCount(stocked: 100, deaths: 150);
      expect(bad.count, 0);
      expect(bad.inconsistent, isTrue);
      expect(biomassG(liveCount: bad.count, avgWeightG: 120), 0);
    });
  });

  group('sampleResult', () {
    test('averages the sample and flags small samples', () {
      expect(
        sampleResult(
          fishCount: 40,
          totalWeightG: 4000,
          config: cfg,
        )!.avgWeightG,
        100.0,
      );
      expect(
        sampleResult(
          fishCount: 40,
          totalWeightG: 4000,
          config: cfg,
        )!.smallSample,
        isFalse,
      );
      expect(
        sampleResult(
          fishCount: 20,
          totalWeightG: 2000,
          config: cfg,
        )!.smallSample,
        isTrue,
      );
    });

    test('an empty sample gives null, not NaN', () {
      expect(sampleResult(fishCount: 0, totalWeightG: 0, config: cfg), isNull);
      expect(sampleResult(fishCount: 30, totalWeightG: 0, config: cfg), isNull);
    });
  });

  test('biomass and survival', () {
    expect(biomassG(liveCount: 950, avgWeightG: 100.0), 95000);
    expect(survivalRate(live: 950, entered: 1000), 0.95);
    expect(survivalRate(live: 0, entered: 0), isNull);
  });

  group('density', () {
    test('needs a surface', () {
      expect(densityPerM2(live: 1500, surfaceM2: 500), 3.0);
      expect(densityPerM2(live: 1500, surfaceM2: null), isNull);
      expect(densityPerM2(live: 1500, surfaceM2: 0), isNull);
    });

    test('status against the structure range', () {
      DensityStatus? s(double? d, [StructureType st = StructureType.earth]) =>
          densityStatus(density: d, structure: st, config: cfg);
      expect(s(1.5), DensityStatus.below);
      expect(s(6.0), DensityStatus.within);
      expect(s(6.5), DensityStatus.above);
      expect(s(60, StructureType.tank), DensityStatus.within);
      expect(s(null), isNull);
    });
  });
}
