import 'config.dart';
import 'types.dart';

enum WaterParam { temperature, ph, oxygen, colour }

enum Direction { low, high }

class WaterIssue {
  const WaterIssue(this.param, this.severity, {this.value, this.direction});

  final WaterParam param;
  final Severity severity;
  final double? value;
  final Direction? direction;
}

/// Problems in one water reading; missing values are skipped.
/// DOMAIN §Water quality.
List<WaterIssue> waterIssues({
  double? temperatureC,
  double? ph,
  double? oxygenMgL,
  WaterColour? colour,
  required DomainConfig config,
}) {
  WaterIssue? outOfRange(WaterParam param, double? v, Range<double> range) {
    if (v == null || range.contains(v)) return null;
    return WaterIssue(param, Severity.warning,
        value: v, direction: v < range.min ? Direction.low : Direction.high);
  }

  return [
    ?outOfRange(WaterParam.temperature, temperatureC, config.temperatureC),
    ?outOfRange(WaterParam.ph, ph, config.ph),
    if (oxygenMgL != null && oxygenMgL < config.minOxygenMgL)
      WaterIssue(WaterParam.oxygen, Severity.danger,
          value: oxygenMgL, direction: Direction.low),
    if (colour == WaterColour.darkGreen || colour == WaterColour.brownTurbid)
      const WaterIssue(WaterParam.colour, Severity.warning),
  ];
}
