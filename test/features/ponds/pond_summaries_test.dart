import 'package:dobo/domain/growth.dart';
import 'package:dobo/features/ponds/pond_growth.dart';
import 'package:dobo/features/ponds/pond_summaries.dart';
import 'package:flutter_test/flutter_test.dart';

WeighPoint _point(DateTime date, double g) => WeighPoint(
  date: date,
  avgWeightG: g,
  liveCount: 1000,
  biomassG: (g * 1000).round(),
  fromSample: true,
);

BatchGrowth _growth(List<WeighPoint> points) => BatchGrowth(
  batchId: 'b1',
  points: points,
  periods: const [],
  trend: null,
  survival: null,
  daysSinceWeighing: 0,
  sampled: true,
);

void main() {
  final mar1 = DateTime(2026, 3, 1);
  final mar15 = DateTime(2026, 3, 15);

  test('weight trend: latest weight and its change since the previous', () {
    final t = weightTrend(_growth([_point(mar1, 138), _point(mar15, 150)]));
    expect(t, (weightG: 150.0, deltaG: 12.0, days: 14));
  });

  test('weight trend with one point: the weight alone', () {
    final t = weightTrend(_growth([_point(mar15, 150)]));
    expect(t, (weightG: 150.0, deltaG: null, days: null));
  });

  test('weight trend shows a loss as a negative change', () {
    final t = weightTrend(_growth([_point(mar1, 150), _point(mar15, 140)]));
    expect(t!.deltaG, -10.0);
  });

  test('weight trend without points is null', () {
    expect(weightTrend(_growth(const [])), isNull);
  });

  test('deaths over the chart window', () {
    final g = PondGrowth(
      batches: const {},
      deathsPerDay: const [0, 3, 1],
      deathsFrom: mar1,
    );
    expect(deathsOverWindow(g), (deaths: 4, days: 3));
  });

  test('health tally: how many and the latest date', () {
    expect(healthTally(const []), isNull);
    expect(healthTally([DateTime(2026, 3, 10), DateTime(2026, 3, 12)]), (
      count: 2,
      latest: DateTime(2026, 3, 12),
    ));
  });
}
