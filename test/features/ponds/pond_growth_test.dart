import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/features/ponds/pond_growth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 3, 20);
  DateTime d(int day) => DateTime(2026, 3, day);
  final stocked = StockingFact(
    batchId: 'b1',
    pondId: 'p1',
    count: 1000,
    avgWeightG: 10,
    date: d(1),
  );

  test('a sample dated tomorrow gives daysSinceWeighing 0', () {
    final g = buildPondGrowth(
      FarmFacts(
        stockings: [stocked],
        samples: [
          SampleFact(batchId: 'b1', pondId: 'p1', avgWeightG: 30, date: d(21)),
        ],
      ),
      'p1',
      ['b1'],
      today,
    );
    expect(g.batches['b1']!.daysSinceWeighing, 0);
    expect(g.batches['b1']!.sampled, isTrue);
  });

  test('never sampled gives sampled false and days since stocking', () {
    final g = buildPondGrowth(FarmFacts(stockings: [stocked]), 'p1', [
      'b1',
    ], today);
    final b = g.batches['b1']!;
    expect((b.sampled, b.daysSinceWeighing), (false, 19));
    expect(b.survival, 1.0);
    expect(b.periods, isEmpty);
    expect(b.trend, isNull);
  });

  test('deathsPerDay has 30 entries ending today', () {
    final g = buildPondGrowth(
      FarmFacts(
        stockings: [stocked],
        logs: [
          LogFact(id: 'a', pondId: 'p1', date: d(20), deaths: 4),
          LogFact(id: 'b', pondId: 'p1', date: d(19), deaths: 2),
        ],
      ),
      'p1',
      ['b1'],
      today,
    );
    expect(g.deathsPerDay, hasLength(deathChartDays));
    expect(g.deathsPerDay.sublist(28), [2, 4]);
    expect(g.deathsFrom, DateTime(2026, 2, 19));
  });
}
