import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/config_overrides.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const d = DomainConfig.defaults;

  Map<String, num> values(DomainConfig c) => {
    for (final k in configKeys) k.key: k.read(c),
  };

  test('every numeric farming number can be overridden', () {
    // DomainConfig minus its feeding guides: 3 phase bounds, 4 ration
    // rates, 3 ration adjustments, 6 density bounds, 4 temperature and pH
    // bounds, oxygen, 2 renewal bounds, 3 sampling, water check, 2 FCR
    // bounds, 3 feed stock, 6 mortality and signs, stop-feeding signs, 6
    // quarantine and prep bounds, fast, harvest hour, 4 dose bounds, 4 pond
    // design bounds, depth, 4 stocking bounds.
    expect(configKeys, hasLength(60));
    expect(configKeys.map((k) => k.key).toSet(), hasLength(60));
    expect(
      configKeys.map((k) => k.key),
      containsAll([
        'rationRate.growout',
        'temperatureC.min',
        'densityPerM2.earth.max',
        'minOxygenMgL',
        'sampleIntervalDays',
        'mortalityLookbackDays',
        'stopFeedingSignDays',
        'harvestHour',
      ]),
    );
  });

  test('writing a key its own value changes nothing', () {
    for (final k in configKeys) {
      expect(values(k.write(d, k.read(d))), values(d), reason: k.key);
    }
  });

  test('writing a key changes that key only', () {
    for (final k in configKeys) {
      final changed = values(k.write(d, k.read(d) + 1));
      expect(changed[k.key], k.read(d) + 1, reason: k.key);
      expect(
        {...changed}..remove(k.key),
        {...values(d)}..remove(k.key),
        reason: k.key,
      );
    }
  });

  test('an override replaces the DOMAIN value', () {
    final c = applyOverrides(d, {'minOxygenMgL': 4});
    expect(c.minOxygenMgL, 4);
    expect(c.temperatureC.max, 32);
    expect(c.rationRate[Phase.growout], 0.04);
  });

  test('integer numbers stay whole', () {
    final c = applyOverrides(d, {'sampleIntervalDays': 10.6});
    expect(c.sampleIntervalDays, 11);
  });

  test('an override that inverts a range is ignored', () {
    expect(applyOverrides(d, {'temperatureC.min': 40}).temperatureC.min, 27);
    expect(applyOverrides(d, {'sampleMinFish': 60}).sampleMinFish, 30);
    expect(applyOverrides(d, {'pregrowMaxG': 300}).pregrowMaxG, 20);
  });

  test('a range moved as a whole is accepted in either order', () {
    final c = applyOverrides(d, {
      'temperatureC.min': 33,
      'temperatureC.max': 36,
    });
    expect((c.temperatureC.min, c.temperatureC.max), (33, 36));
  });

  test('unknown keys and negative values are ignored', () {
    expect(values(applyOverrides(d, {'nope': 1})), values(d));
    expect(applyOverrides(d, {'minOxygenMgL': -1}).minOxygenMgL, 3);
  });
}
