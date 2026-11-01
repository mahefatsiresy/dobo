import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/fcr.dart';
import 'package:dobo/domain/growth.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime day(int d) => DateTime(2026, 3, d);

  StockingFact stock(
    int count,
    double g, {
    String batch = 'b1',
    String pond = 'p1',
    int on = 1,
  }) => StockingFact(
    batchId: batch,
    pondId: pond,
    count: count,
    avgWeightG: g,
    date: day(on),
  );

  SampleFact sample(double g, {int on = 15, String pond = 'p1'}) =>
      SampleFact(batchId: 'b1', pondId: pond, avgWeightG: g, date: day(on));

  TransferFact move(int count, {double? g, int on = 8}) => TransferFact(
    batchId: 'b1',
    fromPondId: 'p1',
    toPondId: 'p2',
    count: count,
    avgWeightG: g,
    date: day(on),
  );

  /// [total] grams of feed spread over days [from]..[to] in pond p1.
  List<LogFact> feed(int total, {int from = 2, int to = 15}) {
    final n = to - from + 1;
    return [
      for (var d = from; d <= to; d++)
        LogFact(
          id: 'f$d',
          pondId: 'p1',
          date: day(d),
          feedG: d == to ? total - (n - 1) * (total ~/ n) : total ~/ n,
        ),
    ];
  }

  LogFact deaths(int count, {int on = 5, String pond = 'p1'}) =>
      LogFact(id: 'd$on$pond', pondId: pond, date: day(on), deaths: count);

  List<FcrPeriod> periods(FarmFacts f) =>
      fcrPeriods(f, batchId: 'b1', pondId: 'p1');

  double value(FcrResult? r) => (r! as FcrValue).value;

  test('arrival is the first point', () {
    final f = FarmFacts(stockings: [stock(1000, 10)]);
    final p = weighPoints(f, batchId: 'b1', pondId: 'p1').first;
    expect(
      (p.avgWeightG, p.liveCount, p.biomassG, p.fromSample),
      (10.0, 1000, 10000, false),
    );
  });

  test('period FCR from stocking to first sample', () {
    final f = FarmFacts(
      stockings: [stock(1000, 10)],
      samples: [sample(30)],
      logs: feed(30000),
    );
    final p = periods(f).single;
    expect(p.feedG, 30000);
    expect(value(p.fcr), closeTo(1.5, 1e-9));
  });

  test('feed on the sample day counts, feed on the arrival day does not', () {
    final f = FarmFacts(
      stockings: [stock(1000, 10)],
      samples: [sample(30)],
      logs: [
        LogFact(id: 'a', pondId: 'p1', date: day(1), feedG: 999),
        LogFact(id: 'b', pondId: 'p1', date: day(15), feedG: 1000),
        LogFact(id: 'c', pondId: 'p1', date: day(16), feedG: 999),
        LogFact(id: 'o', pondId: 'p2', date: day(10), feedG: 999),
      ],
    );
    expect(periods(f).single.feedG, 1000);
  });

  test('move out in the period adds its weight back', () {
    // 800 left at 30 g = 24 000; 200 out at 25 g = 5 000; start 10 000.
    final f = FarmFacts(
      stockings: [stock(1000, 10)],
      transfers: [move(200, g: 25)],
      samples: [sample(30)],
      logs: feed(19000),
    );
    expect(value(periods(f).single.fcr), closeTo(1.0, 1e-9));
  });

  test("unweighed move uses the earlier point's weight", () {
    // 200 out at 10 g = 2 000: gain 24 000 + 2 000 - 10 000 = 16 000.
    final f = FarmFacts(
      stockings: [stock(1000, 10)],
      transfers: [move(200)],
      samples: [sample(30)],
      logs: feed(16000),
    );
    expect(value(periods(f).single.fcr), closeTo(1.0, 1e-9));
  });

  test('move in during the period counts against the gain', () {
    // b1 also stocked in p2, 100 moved into p1 at 20 g = 2 000 in.
    final f = FarmFacts(
      stockings: [
        stock(1000, 10),
        stock(500, 20, pond: 'p2'),
      ],
      transfers: [
        TransferFact(
          batchId: 'b1',
          fromPondId: 'p2',
          toPondId: 'p1',
          count: 100,
          avgWeightG: 20,
          date: day(8),
        ),
      ],
      samples: [sample(30)],
      logs: feed(21000),
    );
    // 1100 × 30 = 33 000; gain 33 000 - (10 000 + 2 000) = 21 000.
    expect(value(periods(f).single.fcr), closeTo(1.0, 1e-9));
  });

  test('shared pond gives null FCR', () {
    final f = FarmFacts(
      stockings: [
        stock(1000, 10),
        stock(500, 12, batch: 'b2', on: 5),
      ],
      samples: [sample(30)],
      logs: feed(30000),
    );
    expect(periods(f).single.fcr, isNull);
  });

  test('no sample yet gives no periods', () {
    final f = FarmFacts(stockings: [stock(1000, 10)], logs: feed(5000));
    expect(periods(f), isEmpty);
  });

  test('negative gain is stalled', () {
    final f = FarmFacts(
      stockings: [stock(1000, 10)],
      samples: [sample(8)],
      logs: feed(5000),
    );
    expect(periods(f).single.fcr, isA<FcrStalled>());
  });

  test('deaths beyond fish: count 0, FCR stalled, survival 0', () {
    final f = FarmFacts(
      stockings: [stock(300, 10)],
      samples: [sample(30)],
      logs: [deaths(500), ...feed(3000, from: 6)],
    );
    expect(weighPoints(f, batchId: 'b1', pondId: 'p1').last.liveCount, 0);
    expect(periods(f).single.fcr, isA<FcrStalled>());
    expect(batchSurvival(f, 'b1'), 0.0);
  });

  test('a sample on the arrival day replaces the arrival point', () {
    final f = FarmFacts(
      stockings: [stock(1000, 10)],
      samples: [sample(11, on: 1)],
    );
    final points = weighPoints(f, batchId: 'b1', pondId: 'p1');
    expect(points.single.fromSample, isTrue);
    expect(points.single.avgWeightG, 11);
  });

  group('fcrTrend', () {
    FcrPeriod p(FcrResult? r) =>
        FcrPeriod(from: day(1), to: day(15), feedG: 1, fcr: r);

    test('higher is worse', () {
      expect(
        fcrTrend([p(const FcrValue(1.5)), p(const FcrValue(1.8))]),
        FcrTrend.worse,
      );
    });
    test('lower is better', () {
      expect(
        fcrTrend([p(const FcrValue(1.8)), p(const FcrValue(1.5))]),
        FcrTrend.better,
      );
    });
    test('equal to 2 decimals is same', () {
      expect(
        fcrTrend([p(const FcrValue(1.5)), p(const FcrValue(1.501))]),
        FcrTrend.same,
      );
    });
    test('null or stalled latest gives null', () {
      expect(fcrTrend([p(const FcrValue(1.5)), p(null)]), isNull);
      expect(fcrTrend([p(const FcrValue(1.5)), p(const FcrStalled())]), isNull);
      expect(fcrTrend([p(const FcrValue(1.5))]), isNull);
    });
    test('skips an earlier uncomputable period', () {
      expect(
        fcrTrend([p(const FcrValue(1.5)), p(null), p(const FcrValue(1.8))]),
        FcrTrend.worse,
      );
    });
  });

  test('batchSurvival over two ponds', () {
    final f = FarmFacts(
      stockings: [stock(1000, 10)],
      transfers: [move(300)],
      logs: [
        deaths(50, on: 10),
        deaths(50, on: 10, pond: 'p2'),
      ],
    );
    expect(batchSurvival(f, 'b1'), closeTo(0.9, 1e-9));
    expect(batchSurvival(f, 'nothing'), isNull);
  });

  test(
    'dailyDeaths fills empty days with 0, a day logged twice counts once',
    () {
      final f = FarmFacts(
        logs: [
          deaths(5, on: 2),
          LogFact(id: 'x', pondId: 'p1', date: day(2), deaths: 1),
          deaths(7, on: 9),
        ],
      );
      expect(dailyDeaths(f, 'p1', from: day(1), to: day(3)), [0, 1, 0]);
    },
  );

  test("liveInPondAtDayStart excludes that day's deaths", () {
    final f = FarmFacts(
      stockings: [stock(1000, 10)],
      logs: [deaths(10, on: 4), deaths(20, on: 5)],
    );
    expect(liveInPondAtDayStart(f, 'p1', day(5)), 990);
    expect(liveInPondAtDayStart(f, 'p1', day(1)), 0);
  });

  test('feed of a pond-day logged twice counts once in the period FCR', () {
    final f = FarmFacts(
      stockings: [stock(1000, 10)],
      samples: [sample(30)],
      logs: [
        ...feed(30000),
        LogFact(id: 'dup', pondId: 'p1', date: day(15), feedG: 3000),
      ],
    );
    // feed() puts 2 142 g on day 15; the duplicate (newest) replaces it.
    expect(
      periods(f).single.feedG,
      30000 - (30000 - 13 * (30000 ~/ 14)) + 3000,
    );
  });
}
