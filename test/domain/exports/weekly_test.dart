import 'package:dobo/domain/alerts/farm_alerts.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/exports/weekly.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // November 2026: Monday 2, 9, 16, 23, 30.
  DateTime d(int day) => farmDateToUtc(DateTime(2026, 11, day));
  final stockedE1 = StockingFact(
    batchId: 'b1',
    pondId: 'e1',
    count: 1000,
    avgWeightG: 20,
    date: d(1),
  );
  LogFact log(
    String id,
    String pond,
    int day, {
    int feedG = 0,
    int deaths = 0,
  }) =>
      LogFact(id: id, pondId: pond, date: d(day), feedG: feedG, deaths: deaths);

  test('wholeWeeks snaps Wednesday–Tuesday to Monday–Sunday', () {
    expect(wholeWeeks(DateTime(2026, 11, 11), DateTime(2026, 11, 17)), (
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 22),
    ));
    expect(wholeWeeks(d(9), d(15)), (
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 15),
    ));
  });

  test('each parameter is the latest of the week that has it', () {
    final rows = weeklySheet(
      facts: FarmFacts(stockings: [stockedE1]),
      readings: [
        ('e1', ReadingInfo(at: d(9), temperatureC: 28, ph: 7, oxygenMgL: 5)),
        ('e1', ReadingInfo(at: d(12), temperatureC: 29, oxygenMgL: 2)),
        ('e1', ReadingInfo(at: d(16), ph: 9)),
      ],
      from: d(9),
      to: d(15),
      pondIds: ['e1'],
    );
    final row = rows.single;
    expect(row.weekStart, DateTime(2026, 11, 9));
    expect((row.temperatureC, row.ph, row.oxygenMgL), (29, 7, 2));
  });

  test('feed and deaths sum the counted logs', () {
    final rows = weeklySheet(
      facts: FarmFacts(
        stockings: [stockedE1],
        logs: [
          log('a', 'e1', 9, feedG: 1000, deaths: 2),
          log('b-old', 'e1', 10, feedG: 900, deaths: 9),
          log('b-new', 'e1', 10, feedG: 1100, deaths: 1),
          log('c', 'e1', 16, feedG: 5000),
        ],
      ),
      from: d(9),
      to: d(15),
      pondIds: ['e1'],
    );
    expect((rows.single.feedG, rows.single.deaths), (2100, 3));
    expect(rows.single.loggedDays, 2);
  });

  test("a batch's latest sample in the week is its weight; two batches give "
      'two entries', () {
    final rows = weeklySheet(
      facts: FarmFacts(
        stockings: [
          stockedE1,
          StockingFact(
            batchId: 'b2',
            pondId: 'e1',
            count: 500,
            avgWeightG: 50,
            date: d(1),
          ),
        ],
        samples: [
          SampleFact(batchId: 'b1', pondId: 'e1', avgWeightG: 40, date: d(9)),
          SampleFact(batchId: 'b1', pondId: 'e1', avgWeightG: 45, date: d(13)),
          SampleFact(batchId: 'b2', pondId: 'e1', avgWeightG: 120, date: d(10)),
        ],
      ),
      from: d(9),
      to: d(15),
      pondIds: ['e1'],
    );
    expect(rows.single.avgWeightGByBatch, {'b1': 45, 'b2': 120});
  });

  test('a pond that held fish with no records shows blank weeks', () {
    final rows = weeklySheet(
      facts: FarmFacts(stockings: [stockedE1]),
      from: d(9),
      to: d(22),
      pondIds: ['e1'],
    );
    expect(rows.map((r) => r.weekStart), [
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 16),
    ]);
    expect(rows.every((r) => r.isEmpty), isTrue);
  });

  test('a pond with no fish and no records is left out', () {
    final rows = weeklySheet(
      facts: FarmFacts(stockings: [stockedE1]),
      from: d(9),
      to: d(15),
      pondIds: ['e1', 'e2'],
    );
    expect(rows.map((r) => r.pondId), ['e1']);
  });

  test('a batch moved mid-week', () {
    final rows = weeklySheet(
      facts: FarmFacts(
        stockings: [stockedE1],
        transfers: [
          TransferFact(
            batchId: 'b1',
            fromPondId: 'e1',
            toPondId: 'e2',
            count: 1000,
            date: d(11),
          ),
        ],
        logs: [
          log('e1', 'e1', 10, feedG: 1000),
          log('e2', 'e2', 12, feedG: 3000),
        ],
        samples: [
          SampleFact(batchId: 'b1', pondId: 'e1', avgWeightG: 40, date: d(10)),
          SampleFact(batchId: 'b1', pondId: 'e2', avgWeightG: 44, date: d(13)),
        ],
      ),
      from: d(9),
      to: d(15),
      pondIds: ['e1', 'e2'],
    );
    expect(
      [for (final r in rows) (r.pondId, r.feedG)],
      [('e1', 1000), ('e2', 3000)],
    );
    expect(
      [for (final r in rows) r.avgWeightGByBatch],
      [
        {'b1': 40.0},
        {'b1': 44.0},
      ],
    );
  });

  test('zero fish, zero feed', () {
    final row = weeklySheet(
      facts: FarmFacts(stockings: [stockedE1]),
      from: d(9),
      to: d(15),
      pondIds: ['e1'],
    ).single;
    expect((row.feedG, row.deaths, row.isEmpty), (0, 0, true));
    expect(row.loggedDays, 0);
    expect(row.avgWeightGByBatch, isEmpty);
  });
}
