import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final d1 = DateTime(2026, 3, 1);

  StockingFact stock(int count, double g) => StockingFact(
    batchId: 'b1',
    pondId: 'p1',
    count: count,
    avgWeightG: g,
    date: d1,
  );

  LogFact log(DateTime date, {int deaths = 0, int feedG = 0}) => LogFact(
    id: 'l${date.toIso8601String()}',
    pondId: 'p1',
    date: date,
    feedG: feedG,
    deaths: deaths,
  );

  test('placementsOf counts deaths from logs', () {
    final f = FarmFacts(
      stockings: [stock(100, 10)],
      logs: [log(DateTime(2026, 3, 2), deaths: 3)],
    );
    expect(placementsOf(f).single.live.count, 97);
  });

  test('placementsOf with until ignores later facts', () {
    final f = FarmFacts(
      stockings: [stock(100, 10)],
      samples: [
        SampleFact(
          batchId: 'b1',
          pondId: 'p1',
          avgWeightG: 30,
          date: DateTime(2026, 3, 10),
        ),
      ],
    );
    expect(
      placementsOf(f, until: DateTime(2026, 3, 9)).single.avgWeightG,
      10,
    );
    expect(
      placementsOf(f, until: DateTime(2026, 3, 10)).single.avgWeightG,
      30,
    );
  });

  test('until is a farm day', () {
    // 20:30 UTC on 09/03 is 23:30 on 09/03 in Madagascar.
    final f = FarmFacts(
      stockings: [stock(100, 10)],
      logs: [log(DateTime.utc(2026, 3, 9, 20, 30), deaths: 5)],
    );
    expect(
      placementsOf(f, until: DateTime(2026, 3, 9)).single.live.count,
      95,
    );
    expect(
      placementsOf(f, until: DateTime(2026, 3, 8)).single.live.count,
      100,
    );
  });

  test('empty facts give no placements', () {
    expect(placementsOf(const FarmFacts.empty()), isEmpty);
  });
}
