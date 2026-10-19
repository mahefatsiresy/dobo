import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/domain/water.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;

  test('readings in range or missing raise nothing', () {
    expect(waterIssues(config: cfg), isEmpty);
    expect(
      waterIssues(
        temperatureC: 27,
        ph: 6.5,
        oxygenMgL: 3.0,
        colour: WaterColour.lightGreen,
        config: cfg,
      ),
      isEmpty,
    );
    expect(waterIssues(temperatureC: 32, ph: 8.5, config: cfg), isEmpty);
  });

  test('temperature and pH out of range are warnings with a direction', () {
    final t = waterIssues(temperatureC: 26, config: cfg).single;
    expect(
      (t.param, t.severity, t.direction),
      (WaterParam.temperature, Severity.warning, Direction.low),
    );
    expect(
      waterIssues(temperatureC: 33, config: cfg).single.direction,
      Direction.high,
    );
    expect(waterIssues(ph: 8.6, config: cfg).single.param, WaterParam.ph);
  });

  test('low oxygen is danger', () {
    final o = waterIssues(oxygenMgL: 2.9, config: cfg).single;
    expect((o.param, o.severity), (WaterParam.oxygen, Severity.danger));
  });

  test('turbid water is a colour warning; issues accumulate', () {
    expect(
      waterIssues(colour: WaterColour.brownTurbid, config: cfg).single.param,
      WaterParam.colour,
    );
    expect(waterIssues(temperatureC: 26, oxygenMgL: 1, config: cfg).length, 2);
  });
}
