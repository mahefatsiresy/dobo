import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/feed_lots.dart';
import 'package:dobo/domain/feed_stock.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/domain/stock.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;
  DateTime day(int d) => DateTime(2026, 3, d);
  final today = day(20);

  FeedLotFact lot(
    String id,
    int kg, {
    Phase phase = Phase.growout,
    int made = 1,
    int delivered = 5,
  }) => FeedLotFact(
    id: id,
    phase: phase,
    weightG: kg * 1000,
    manufacturedOn: day(made),
    deliveredOn: day(delivered),
  );

  LogFact log(int kg, {int on = 10, String? lotId, String pond = 'p1'}) =>
      LogFact(
        id: 'l$on$pond$kg',
        pondId: pond,
        date: day(on),
        feedG: kg * 1000,
        feedLotId: lotId,
      );

  FeedStock stockOf(
    List<FeedLotFact> lots, {
    List<FeedDiscardFact> discards = const [],
    List<LogFact> logs = const [],
    DateTime? on,
  }) => feedStock(
    lots: lots,
    discards: discards,
    countedLogs: logs,
    today: on ?? today,
    config: cfg,
  );

  int balance(FeedStock s, String id) =>
      s.lots.singleWhere((b) => b.lot.id == id).balanceG;

  test('a 25 kg lot with 3 kg discarded and 4 kg drawn has 18 kg', () {
    final s = stockOf(
      [lot('a', 25)],
      discards: [FeedDiscardFact(lotId: 'a', weightG: 3000, date: day(8))],
      logs: [log(4, lotId: 'a')],
    );
    expect(balance(s, 'a'), 18000);
    expect((s.onHandG, s.overdrawnG), (18000, 0));
  });

  test('logs without a lot draw from the oldest lot with a balance', () {
    final s = stockOf(
      [lot('new', 25, made: 3), lot('old', 5, made: 1)],
      logs: [log(4, on: 10), log(3, on: 11)],
    );
    expect(balance(s, 'old'), 0);
    expect(balance(s, 'new'), 23000);
    expect(s.overdrawnG, 0);
  });

  test('logs before the first delivery draw nothing', () {
    final s = stockOf([lot('a', 25, delivered: 5)], logs: [log(4, on: 3)]);
    expect((balance(s, 'a'), s.overdrawnG), (25000, 0));
  });

  test('drawing 30 kg from a 25 kg lot leaves 0 and 5 kg overdrawn', () {
    final s = stockOf(
      [lot('a', 25)],
      logs: [
        log(20, on: 10, lotId: 'a'),
        log(10, on: 11, lotId: 'a'),
      ],
    );
    expect((balance(s, 'a'), s.onHandG, s.overdrawnG), (0, 0, 5000));
  });

  test('a lot at 90 days is expired and not on hand', () {
    final s = stockOf([
      lot('a', 25, made: 1),
    ], on: day(1).add(const Duration(days: 90)));
    final a = s.lots.single;
    expect((a.age, a.balanceG), (FeedAge.expired, 25000));
    expect((s.onHandG, s.expiredG), (0, 25000));
  });

  test("daily usage is the last 7 days' feed ÷ 7, and days left is on hand "
      '÷ usage', () {
    final s = stockOf(
      [lot('a', 100)],
      logs: [
        log(7, on: 12), // 8 days before the 20th: outside the window
        for (var d = 14; d <= 20; d++) log(2, on: d),
      ],
    );
    expect(s.dailyUsageG, 2000);
    expect(s.onHandG, 100000 - 7000 - 14000);
    expect(s.daysLeft, closeTo(79000 / 2000, 1e-9));
  });

  test('with no feed logged, days left is null', () {
    final s = stockOf([lot('a', 25)]);
    expect((s.dailyUsageG, s.daysLeft), (0, null));
  });

  test("the default lot matches the pond's phase, oldest first", () {
    final s = stockOf([
      lot('fry', 25, phase: Phase.fry, made: 1),
      lot('grow-new', 25, made: 4),
      lot('grow-old', 25, made: 2),
    ]);
    expect(defaultFeedLot(stock: s, pondPhase: Phase.growout), 'grow-old');
  });

  test("with no lot of the pond's phase, the default is the oldest usable "
      'lot', () {
    final s = stockOf([
      lot('a', 25, phase: Phase.fry, made: 3),
      lot('b', 25, phase: Phase.pregrow, made: 2),
    ]);
    expect(defaultFeedLot(stock: s, pondPhase: Phase.finishing), 'b');
    expect(defaultFeedLot(stock: s, pondPhase: null), 'b');
  });

  test('with every lot empty or expired, there is no default', () {
    final s = stockOf(
      [lot('empty', 5, made: 15), lot('expired', 25, made: 1)],
      logs: [log(5, on: 16, lotId: 'empty')],
      on: day(1).add(const Duration(days: 95)),
    );
    expect(defaultFeedLot(stock: s, pondPhase: Phase.growout), isNull);
  });

  test('pondPhase picks the batch with the most biomass', () {
    Placement at(String b, int live, double g) => Placement(
      batchId: b,
      pondId: 'p1',
      live: LiveCount(live, inconsistent: false),
      avgWeightG: g,
    );
    expect(
      pondPhase([at('small', 1000, 4), at('big', 200, 50)], 'p1', cfg),
      Phase.growout,
    );
    expect(pondPhase([at('gone', 0, 50)], 'p1', cfg), isNull);
    expect(pondPhase(const [], 'p1', cfg), isNull);
  });
}
