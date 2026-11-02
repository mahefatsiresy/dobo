import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/alerts/farm_alerts.dart';
import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/domain/people.dart';
import 'package:dobo/domain/report/build_report.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/domain/water.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;

  /// A hand-entered March date, as the database stores it.
  DateTime d(int day) => farmDateToUtc(DateTime(2026, 3, day));

  const people = PeopleDirectory(
    people: {'rakoto': 'Rakoto', 'hery': 'Hery'},
    accounts: {
      'worker': AccountRef(name: 'rakoto', personId: 'rakoto'),
      'member': AccountRef(name: 'Soa'),
    },
  );

  StockingFact stock({String batch = 'l1', String pond = 'e1', int on = 1}) =>
      StockingFact(
        batchId: batch,
        pondId: pond,
        count: 1000,
        avgWeightG: 10,
        date: d(on),
      );

  LogFact log(
    int on, {
    String pond = 'e1',
    int feedG = 0,
    int deaths = 0,
    Set<WarningSign> signs = const {},
    String by = 'worker',
    String? observedBy,
    String? id,
  }) => LogFact(
    id: id ?? '$pond-$on-$by-$feedG-$deaths',
    pondId: pond,
    date: d(on),
    feedG: feedG,
    deaths: deaths,
    signs: signs,
    enteredBy: by,
    observedBy: observedBy,
  );

  ReportContent build({
    List<StockingFact>? stockings,
    List<TransferFact> transfers = const [],
    List<SampleFact> samples = const [],
    List<LogFact> logs = const [],
    Map<String, BatchInfo>? batches,
    List<Alert> alerts = const [],
    Map<String, ReadingInfo> readings = const {},
    List<(String, HealthLine)> healthLines = const [],
    List<(String, TreatmentLine)> treatments = const [],
    DateTime? from,
  }) => buildReportContent(
    ReportInputs(
      header: ReportHeader(
        siteName: 'Ambohidratrimo',
        visitDay: d(20),
        memberName: 'Soa',
        periodFrom: from ?? d(13),
        periodTo: d(20),
        builtAt: d(20),
      ),
      facts: FarmFacts(
        stockings: stockings ?? [stock()],
        transfers: transfers,
        samples: samples,
        logs: logs,
      ),
      pondCodes: const {'e1': 'E1', 'e2': 'E2'},
      batchCodes: const {'l1': 'L1', 'l2': 'L2'},
      batches:
          batches ??
          const {'l1': BatchInfo(id: 'l1', status: BatchStatus.active)},
      alerts: alerts,
      latestReadings: readings,
      healthLines: healthLines,
      treatments: treatments,
      people: people,
      config: cfg,
    ),
  );

  group('reportPeriod', () {
    test('with no previous report covers the 7 days up to the visit', () {
      expect(reportPeriod(visitDay: d(20)), (d(13), d(20)));
    });
    test('starts on the previous report\'s last day', () {
      expect(reportPeriod(visitDay: d(20), previousPeriodTo: d(15)), (
        d(15),
        d(20),
      ));
    });
    test('a previous report on the same day gives one day', () {
      expect(reportPeriod(visitDay: d(20), previousPeriodTo: d(20)), (
        d(20),
        d(20),
      ));
    });
  });

  test('deaths are split by who observed them', () {
    final c = build(
      logs: [
        log(14, deaths: 9),
        log(15, deaths: 3, by: 'member', observedBy: 'hery'),
      ],
    );
    final h = c.health.single;
    expect((h.pondId, h.deaths), ('e1', 12));
    expect(
      [for (final o in h.byObserver) (o.name, o.deaths)],
      [('Rakoto', 9), ('Hery', 3)],
    );
  });

  test('an observer this phone does not know is counted with no name', () {
    final c = build(logs: [log(14, deaths: 2, observedBy: 'stranger')]);
    expect(c.health.single.byObserver.single.name, isNull);
  });

  test('a pond-day logged on two phones counts once', () {
    final dup = Alert(
      AlertKind.duplicateDailyLog,
      Severity.warning,
      pondId: 'e1',
      facts: {
        'date': d(14),
        'logIds': ['a', 'b'],
      },
    );
    final c = build(
      logs: [
        log(14, id: 'a', feedG: 4000, deaths: 5),
        log(14, id: 'b', feedG: 4000, deaths: 5, by: 'member'),
      ],
      alerts: [dup],
    );
    expect(c.health.single.deaths, 5);
    expect(c.feed.single.feedG, 4000);
    expect(c.feedTotalG, 4000);
    expect(c.alerts.single.kind, AlertKind.duplicateDailyLog);
  });

  test('logs outside the period are left out', () {
    final c = build(
      logs: [log(12, deaths: 4, feedG: 1000), log(21, deaths: 1)],
    );
    expect(c.health, isEmpty);
    expect(c.feed, isEmpty);
  });

  test('a log at 23:30 Madagascar on the boundary day counts', () {
    final late = LogFact(
      id: 'late',
      pondId: 'e1',
      // 13/03 23:30 in Madagascar is 20:30 UTC.
      date: DateTime.utc(2026, 3, 13, 20, 30),
      deaths: 2,
      enteredBy: 'worker',
    );
    final c = build(logs: [late]);
    expect(c.health.single.deaths, 2);
  });

  test('signs from logs are grouped by day', () {
    final c = build(
      logs: [
        log(14, signs: {WarningSign.rubbing}),
        log(14, pond: 'e1', by: 'member', signs: {WarningSign.whiteSpots}),
      ],
    );
    final s = c.health.single.signs.single;
    expect(s.date, d(14));
    expect(s.signs, {WarningSign.rubbing, WarningSign.whiteSpots});
  });

  test('health events and treatments are grouped by pond', () {
    final c = build(
      healthLines: [
        ('e2', HealthLine(at: d(15), signs: const {WarningSign.rubbing})),
      ],
      treatments: [
        ('e2', TreatmentLine(at: d(16), product: 'Sel', dose: '3 g/L')),
      ],
    );
    final h = c.health.single;
    expect((h.pondId, h.events.length, h.treatments.length), ('e2', 1, 1));
  });

  test('growth line is estimated from placements', () {
    final c = build(
      samples: [
        SampleFact(batchId: 'l1', pondId: 'e1', avgWeightG: 30, date: d(15)),
      ],
      logs: [log(10, feedG: 30000, deaths: 10)],
    );
    final g = c.growth.single;
    expect((g.batchId, g.pondId, g.avgWeightG), ('l1', 'e1', 30.0));
    expect(g.weighedOn, d(15));
    expect((g.liveCount, g.biomassG), (990, 29700));
    expect(g.fcr, closeTo(30000 / (29700 - 10000), 1e-9));
    expect(g.fcrNote, isNull);
    expect(g.survival, closeTo(0.99, 1e-9));
  });

  test('no sample yet gives FcrNote.noSample', () {
    final g = build().growth.single;
    expect((g.fcr, g.fcrNote), (null, FcrNote.noSample));
    expect(g.avgWeightG, 10.0);
  });

  test('negative gain gives FcrNote.stalled', () {
    final g = build(
      samples: [
        SampleFact(batchId: 'l1', pondId: 'e1', avgWeightG: 8, date: d(15)),
      ],
      logs: [log(10, feedG: 5000)],
    ).growth.single;
    expect((g.fcr, g.fcrNote), (null, FcrNote.stalled));
  });

  test('a shared pond gives FcrNote.shared', () {
    final c = build(
      stockings: [
        stock(),
        stock(batch: 'l2', on: 5),
      ],
      samples: [
        SampleFact(batchId: 'l1', pondId: 'e1', avgWeightG: 30, date: d(15)),
      ],
      batches: const {
        'l1': BatchInfo(id: 'l1', status: BatchStatus.active),
        'l2': BatchInfo(id: 'l2', status: BatchStatus.active),
      },
    );
    final l1 = c.growth.firstWhere((g) => g.batchId == 'l1');
    expect(l1.fcrNote, FcrNote.shared);
  });

  test('a pond whose fish all died has no growth line, its deaths stay', () {
    final c = build(logs: [log(14, deaths: 1000)]);
    expect(c.growth, isEmpty);
    expect(c.water, isEmpty);
    expect(c.health.single.deaths, 1000);
  });

  test('water lists ponds holding fish with their latest reading', () {
    final c = build(
      stockings: [
        stock(),
        stock(batch: 'l2', pond: 'e2'),
      ],
      batches: const {
        'l1': BatchInfo(id: 'l1', status: BatchStatus.active),
        'l2': BatchInfo(id: 'l2', status: BatchStatus.active),
      },
      readings: {'e1': ReadingInfo(at: d(19), ph: 7.2, oxygenMgL: 2.5)},
    );
    expect([for (final w in c.water) w.pondId], ['e1', 'e2']);
    final e1 = c.water.first;
    expect((e1.at, e1.ph, e1.oxygenMgL), (d(19), 7.2, 2.5));
    expect(e1.issues.single.param, WaterParam.oxygen);
    expect(c.water.last.at, isNull);
  });

  test('next: weighing, quarantine release and planned harvest by date', () {
    final c = build(
      stockings: [
        stock(),
        stock(batch: 'l2', pond: 'e2', on: 10),
      ],
      batches: {
        'l1': BatchInfo(
          id: 'l1',
          status: BatchStatus.active,
          plannedHarvestOn: d(30),
        ),
        'l2': const BatchInfo(id: 'l2', status: BatchStatus.quarantine),
      },
    );
    final items = [for (final n in c.next) (n.kind, n.date, n.batchId)];
    expect(
      items,
      [
        (NextKind.sample, d(1 + cfg.sampleIntervalDays), 'l1'),
        (NextKind.sample, d(10 + cfg.sampleIntervalDays), 'l2'),
        (NextKind.quarantineRelease, d(10 + cfg.quarantineDays.min), 'l2'),
        (NextKind.harvest, d(30), 'l1'),
      ]..sort((a, b) => a.$2.compareTo(b.$2)),
    );
  });

  test('a planned harvest before the visit day is left out', () {
    final c = build(
      batches: {
        'l1': BatchInfo(
          id: 'l1',
          status: BatchStatus.active,
          plannedHarvestOn: d(18),
        ),
      },
    );
    expect(c.next.where((n) => n.kind == NextKind.harvest), isEmpty);
  });

  test('an empty farm and an empty visit give empty sections', () {
    final c = build(stockings: const [], batches: const {});
    expect(c.health, isEmpty);
    expect(c.water, isEmpty);
    expect(c.growth, isEmpty);
    expect(c.feed, isEmpty);
    expect(c.next, isEmpty);
    expect(c.feedTotalG, 0);
    expect(c.feedStock, isNull);
  });

  test('header, summary, codes and alerts are carried as given', () {
    final c = build();
    expect(c.header.siteName, 'Ambohidratrimo');
    expect(c.pondCodes['e1'], 'E1');
    expect(c.format, ReportContent.currentFormat);
  });
}
