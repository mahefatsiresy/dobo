import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/alerts/farm_alerts.dart';
import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/feed_lots.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/domain/prep.dart';
import 'package:dobo/domain/stock.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/domain/water.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;

  /// A hand-entered March date, as the database stores it.
  DateTime d(int day) => farmDateToUtc(DateTime(2026, 3, day));

  /// 20/03 09:00 in Madagascar.
  final now = farmTimeToUtc(DateTime(2026, 3, 20), 9, 0);

  const e1 = PondInfo(
    id: 'e1',
    code: 'E1',
    structure: StructureType.earth,
    surfaceM2: 500,
  );
  const e2 = PondInfo(
    id: 'e2',
    code: 'E2',
    structure: StructureType.earth,
    surfaceM2: 500,
  );

  StockingFact stock({int count = 1000, int on = 1, String pond = 'e1'}) =>
      StockingFact(
        batchId: 'l1',
        pondId: pond,
        count: count,
        avgWeightG: 10,
        date: d(on),
      );

  SampleFact sample(double g, int on) =>
      SampleFact(batchId: 'l1', pondId: 'e1', avgWeightG: g, date: d(on));

  LogFact log(
    int on, {
    String id = '',
    int feedG = 0,
    int deaths = 0,
    Set<WarningSign> signs = const {},
    WaterColour? colour,
    String pond = 'e1',
  }) => LogFact(
    id: id.isEmpty ? '$pond-$on-$feedG-$deaths' : id,
    pondId: pond,
    date: d(on),
    feedG: feedG,
    deaths: deaths,
    signs: signs,
    waterColour: colour,
  );

  List<Alert> alerts({
    List<StockingFact>? stockings,
    List<TransferFact> transfers = const [],
    List<SampleFact> samples = const [],
    List<LogFact> logs = const [],
    List<PondInfo> ponds = const [e1, e2],
    BatchStatus status = BatchStatus.active,
    DateTime? plannedHarvestOn,
    Map<String, ReadingInfo>? readings,
    List<PondSigns> healthSigns = const [],
    DateTime? at,
    FeedStock? feedStock,
    Map<String, PrepProgress> prep = const {},
  }) => farmAlerts(
    facts: FarmFacts(
      stockings: stockings ?? [stock()],
      transfers: transfers,
      samples: samples,
      logs: logs,
    ),
    ponds: ponds,
    batches: {
      'l1': BatchInfo(
        id: 'l1',
        status: status,
        plannedHarvestOn: plannedHarvestOn,
      ),
    },
    // A fresh reading keeps "water check due" out of unrelated tests.
    latestReadings:
        readings ?? {'e1': ReadingInfo(at: d(19), temperatureC: 28)},
    healthSigns: healthSigns,
    feedStock: feedStock,
    prep: prep,
    now: at ?? now,
    config: cfg,
  );

  Iterable<Alert> ofKind(List<Alert> all, AlertKind k) =>
      all.where((a) => a.kind == k);

  test(
    'water: low oxygen is danger, high pH is warning, stocked ponds only',
    () {
      final all = alerts(
        readings: {
          'e1': ReadingInfo(at: d(19), oxygenMgL: 2, ph: 9),
          'e2': ReadingInfo(at: d(19), oxygenMgL: 2),
        },
      );
      final water = ofKind(all, AlertKind.waterOutOfRange).toList();
      expect(water.every((a) => a.pondId == 'e1'), isTrue);
      expect(
        {for (final a in water) a.facts['param']: a.severity},
        {WaterParam.oxygen: Severity.danger, WaterParam.ph: Severity.warning},
      );
    },
  );

  test('water colour from a newer daily log wins over an older reading', () {
    final newer = alerts(
      readings: {'e1': ReadingInfo(at: d(18), colour: WaterColour.clear)},
      logs: [log(19, colour: WaterColour.darkGreen)],
    );
    expect(
      ofKind(newer, AlertKind.waterOutOfRange).single.facts['param'],
      WaterParam.colour,
    );
    final older = alerts(
      readings: {'e1': ReadingInfo(at: d(18), colour: WaterColour.clear)},
      logs: [log(17, colour: WaterColour.darkGreen)],
    );
    expect(ofKind(older, AlertKind.waterOutOfRange), isEmpty);
  });

  test('water check due with no reading, none on an empty pond', () {
    final due = ofKind(alerts(readings: {}), AlertKind.waterCheckDue);
    expect(due.map((a) => a.pondId), ['e1']);
  });

  test('sample due 14 days after arrival, cleared by a sample', () {
    expect(ofKind(alerts(), AlertKind.sampleDue).single.facts['daysSince'], 19);
    expect(
      ofKind(alerts(samples: [sample(15, 18)]), AlertKind.sampleDue),
      isEmpty,
    );
  });

  test('growth stalled comes from the latest period', () {
    final all = alerts(samples: [sample(8, 18)]);
    expect(ofKind(all, AlertKind.growthStalled).single.batchId, 'l1');
  });

  test('FCR worsening after two rises', () {
    // Gains of 2 000 g each; feed 2 000, 3 000, 4 000 → 1.0, 1.5, 2.0.
    final all = alerts(
      samples: [sample(12, 5), sample(14, 10), sample(16, 15)],
      logs: [log(3, feedG: 2000), log(7, feedG: 3000), log(12, feedG: 4000)],
    );
    expect(ofKind(all, AlertKind.fcrWorsening), hasLength(1));
    expect(ofKind(all, AlertKind.growthStalled), isEmpty);
  });

  test('phase change when the latest sample crosses 20 g', () {
    final all = alerts(samples: [sample(21, 18)]);
    final a = ofKind(all, AlertKind.phaseChange).single;
    expect((a.facts['from'], a.facts['to']), (Phase.pregrow, Phase.growout));
  });

  test('density below range', () {
    expect(ofKind(alerts(), AlertKind.densityOutOfRange), isEmpty);
    final low = ofKind(
      alerts(stockings: [stock(count: 400)]),
      AlertKind.densityOutOfRange,
    );
    expect(low.single.facts['status'], DensityStatus.below);
  });

  test('mortality spike within the last 3 days carries its date', () {
    final recent = ofKind(
      alerts(logs: [log(19, deaths: 50)]),
      AlertKind.mortalitySpike,
    );
    expect(recent.single.facts['date'], DateTime(2026, 3, 19));
    expect(
      ofKind(alerts(logs: [log(16, deaths: 50)]), AlertKind.mortalitySpike),
      isEmpty,
    );
  });

  test('500 deaths in a pond of 300 raises mortality spike', () {
    final all = alerts(
      stockings: [stock(count: 300)],
      logs: [log(19, deaths: 500)],
    );
    expect(ofKind(all, AlertKind.mortalitySpike), hasLength(1));
  });

  test('warning sign from a health event', () {
    final all = alerts(
      healthSigns: [
        PondSigns('e2', DatedSigns(d(19), const {WarningSign.rubbing})),
      ],
    );
    expect(ofKind(all, AlertKind.warningSignSeen).single.pondId, 'e2');
  });

  test('a future-dated sign still alerts', () {
    final all = alerts(
      logs: [
        log(25, signs: const {WarningSign.whiteSpots}),
      ],
    );
    expect(ofKind(all, AlertKind.warningSignSeen), hasLength(1));
  });

  test('quarantine ending at day 7 for a quarantine batch only', () {
    List<Alert> at(int stockedOn, BatchStatus s) => ofKind(
      alerts(
        stockings: [stock(on: stockedOn)],
        status: s,
      ),
      AlertKind.quarantineEnding,
    ).toList();
    expect(at(13, BatchStatus.quarantine), hasLength(1));
    expect(at(14, BatchStatus.quarantine), isEmpty);
    expect(at(13, BatchStatus.active), isEmpty);
  });

  test('pre-harvest fast opens 48 h before 06:00 on the harvest day', () {
    final fed = ofKind(
      alerts(plannedHarvestOn: d(21), logs: [log(20, feedG: 3000)]),
      AlertKind.preHarvestFast,
    );
    expect(fed.single.facts['fedDuringFast'], isTrue);
    final notFed = ofKind(
      alerts(plannedHarvestOn: d(21), logs: [log(18, feedG: 3000)]),
      AlertKind.preHarvestFast,
    );
    expect(notFed.single.facts['fedDuringFast'], isFalse);
    // 05:59 on 19/03 is before the window of a harvest on 21/03.
    expect(
      ofKind(
        alerts(
          plannedHarvestOn: d(21),
          at: farmTimeToUtc(DateTime(2026, 3, 19), 5, 59),
        ),
        AlertKind.preHarvestFast,
      ),
      isEmpty,
    );
    expect(
      ofKind(alerts(plannedHarvestOn: d(23)), AlertKind.preHarvestFast),
      isEmpty,
    );
  });

  test('duplicate pond-day lists both logs', () {
    final all = alerts(
      logs: [
        log(19, id: 'a'),
        log(19, id: 'b'),
        log(18, id: 'c'),
      ],
    );
    final dup = ofKind(all, AlertKind.duplicateDailyLog).single;
    expect(dup.pondId, 'e1');
    expect(dup.facts['date'], DateTime(2026, 3, 19));
    expect(dup.facts['logIds'], ['a', 'b']);
  });

  test('sorted danger first, then kind order, then pond code', () {
    final all = alerts(
      stockings: [
        stock(),
        stock(pond: 'e2'),
      ],
      readings: {},
      logs: [log(19, deaths: 50, pond: 'e2')],
    );
    final kinds = [for (final a in all) (a.kind, a.pondId)];
    expect(kinds.first, (AlertKind.mortalitySpike, 'e2'));
    expect(
      kinds.where((k) => k.$1 == AlertKind.waterCheckDue).map((k) => k.$2),
      ['e1', 'e2'],
    );
    final firstWarning = all.indexWhere((a) => a.severity == Severity.warning);
    expect(
      all.skip(firstWarning).every((a) => a.severity == Severity.warning),
      isTrue,
    );
    expect(
      kinds.indexOf((AlertKind.sampleDue, 'e1')),
      lessThan(kinds.indexOf((AlertKind.waterCheckDue, 'e1'))),
    );
  });

  test('today is the farm day, not the UTC day', () {
    // 21:30 UTC on 14/03 is 00:30 on 15/03 in Madagascar: 14 days after
    // the stocking, so sampling is due; a spike on 12/03 is out of the
    // 15, 14, 13 window.
    final at = DateTime.utc(2026, 3, 14, 21, 30);
    final all = alerts(
      at: at,
      logs: [log(12, deaths: 50)],
      readings: {'e1': ReadingInfo(at: d(14), temperatureC: 28)},
    );
    expect(ofKind(all, AlertKind.sampleDue), hasLength(1));
    expect(ofKind(all, AlertKind.mortalitySpike), isEmpty);
  });

  test('ponds not passed (archived) raise nothing', () {
    final all = alerts(
      stockings: [
        stock(),
        stock(pond: 'e9'),
      ],
      logs: [
        log(19, deaths: 50, pond: 'e9'),
        log(19, pond: 'e9', id: 'x'),
      ],
    );
    expect(all.where((a) => a.pondId == 'e9'), isEmpty);
  });

  test('closed batches raise no batch alerts', () {
    final all = alerts(status: BatchStatus.closed);
    expect(ofKind(all, AlertKind.sampleDue), isEmpty);
  });

  test('nextTimedChange: the next fast opening or closing after now', () {
    final batches = [
      BatchInfo(id: 'a', status: BatchStatus.active, plannedHarvestOn: d(22)),
      BatchInfo(id: 'b', status: BatchStatus.active, plannedHarvestOn: d(30)),
      const BatchInfo(id: 'c', status: BatchStatus.active),
    ];
    // 20/03 09:00: the fast for 22/03 is open; it closes 22/03 06:00.
    expect(
      nextTimedChange(batches: batches, now: now, config: cfg),
      farmTimeToUtc(DateTime(2026, 3, 22), 6, 0),
    );
    expect(
      nextTimedChange(
        batches: batches,
        now: farmTimeToUtc(DateTime(2026, 3, 19), 9, 0),
        config: cfg,
      ),
      farmTimeToUtc(DateTime(2026, 3, 20), 6, 0),
    );
    expect(
      nextTimedChange(batches: batches.sublist(2), now: now, config: cfg),
      isNull,
    );
  });

  test('FCR worsening does not reach across a shared period', () {
    // 1.0, 1.5, then L2 shares E1 from 12/03 to 14/03 (no FCR), then 2.0:
    // the rises are not consecutive.
    final all = alerts(
      stockings: [
        stock(),
        StockingFact(
          batchId: 'l2',
          pondId: 'e1',
          count: 100,
          avgWeightG: 10,
          date: _d12,
        ),
      ],
      transfers: [
        TransferFact(
          batchId: 'l2',
          fromPondId: 'e1',
          toPondId: 'e2',
          count: 100,
          date: _d14,
        ),
      ],
      samples: [sample(12, 5), sample(14, 10), sample(16, 15), sample(18, 18)],
      logs: [
        log(3, feedG: 2000),
        log(7, feedG: 3000),
        log(12, feedG: 9000),
        log(17, feedG: 4000),
      ],
    );
    expect(ofKind(all, AlertKind.fcrWorsening), isEmpty);
  });

  group('M7: feed and preparation', () {
    FeedStock stockOf(List<(String, int, int)> lots, {int usageG = 0}) {
      // (id, kg, manufactured that many days before today)
      final facts = [
        for (final (id, kg, age) in lots)
          FeedLotFact(
            id: id,
            phase: Phase.growout,
            weightG: kg * 1000,
            manufacturedOn: d(20).subtract(Duration(days: age)),
            deliveredOn: d(1),
          ),
      ];
      return feedStock(
        lots: facts,
        discards: const [],
        countedLogs: [
          for (var day = 14; day <= 20; day++)
            LogFact(id: 'u$day', pondId: 'e1', date: d(day), feedG: usageG),
        ],
        today: d(20),
        config: cfg,
      );
    }

    test('a lot at 61 days with a balance warns, at 90 days is danger, '
        'empty lot is silent', () {
      final all = alerts(
        feedStock: stockOf([('old', 25, 61), ('expired', 25, 90)]),
      );
      final aged = ofKind(all, AlertKind.feedTooOld).toList();
      expect(
        {for (final a in aged) a.facts['feedLotId']: a.severity},
        {'old': Severity.warning, 'expired': Severity.danger},
      );
      final empty = stockOf([('used', 7, 61)], usageG: 1000);
      expect(empty.lots.single.balanceG, 0);
      expect(ofKind(alerts(feedStock: empty), AlertKind.feedTooOld), isEmpty);
    });

    test('stock covering 5 days warns once, without a pond', () {
      // 84 kg delivered, 7 kg a day for a week: 35 kg left, 5 days.
      final all = alerts(feedStock: stockOf([('a', 84, 10)], usageG: 7000));
      final low = ofKind(all, AlertKind.feedStockLow).single;
      expect((low.pondId, low.facts['daysLeft']), (null, 5.0));
    });

    test('drained 5 days ago with no dry step is a prep alert', () {
      final p = prepProgress(
        pondId: 'e2',
        steps: [
          PrepStepFact(
            id: 's1',
            pondId: 'e2',
            step: PrepStep.drain,
            date: d(15),
          ),
        ],
        lastDayWithFish: null,
        config: cfg,
      );
      final due = ofKind(alerts(prep: {'e2': p}), AlertKind.prepStepDue).single;
      expect((due.pondId, due.facts['waitingStep']), ('e2', PrepStep.dry));
    });

    test('a refilled pond from an earlier cycle raises nothing', () {
      final p = prepProgress(
        pondId: 'e2',
        steps: [
          PrepStepFact(id: 's1', pondId: 'e2', step: PrepStep.fill, date: d(2)),
        ],
        lastDayWithFish: d(10),
        config: cfg,
      );
      expect(ofKind(alerts(prep: {'e2': p}), AlertKind.prepStepDue), isEmpty);
    });
  });
}

final _d12 = DateTime.utc(2026, 3, 12, 9);
final _d14 = DateTime.utc(2026, 3, 14, 9);
