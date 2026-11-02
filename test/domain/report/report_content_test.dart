import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/growth.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/stock.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/domain/water.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime.utc(2026, 3, 19, 21);

  /// Representative facts for every kind, as the rules write them.
  final factsByKind = <AlertKind, Map<String, Object?>>{
    AlertKind.waterOutOfRange: {
      'param': WaterParam.oxygen,
      'value': 2.5,
      'direction': Direction.low,
    },
    AlertKind.fcrWorsening: {},
    AlertKind.growthStalled: {},
    AlertKind.mortalitySpike: {
      'deathsToday': 20,
      'trailingAverage': 1.5,
      'date': day,
    },
    AlertKind.warningSignSeen: {
      'signs': {WarningSign.rubbing, WarningSign.whiteSpots},
    },
    AlertKind.densityOutOfRange: {
      'status': DensityStatus.above,
      'density': 4.2,
    },
    AlertKind.phaseChange: {'from': Phase.fry, 'to': Phase.pregrow},
    AlertKind.sampleDue: {'daysSince': 15},
    AlertKind.waterCheckDue: {},
    AlertKind.quarantineEnding: {'days': 21, 'recommendedDays': 30},
    AlertKind.preHarvestFast: {'fedDuringFast': true},
    AlertKind.feedStockLow: {'daysLeft': 3},
    AlertKind.feedTooOld: {'feedLotId': 'f1', 'age': 95},
    AlertKind.prepStepDue: {'waitingStep': PrepStep.dry},
    AlertKind.duplicateDailyLog: {
      'date': day,
      'logIds': ['a', 'b'],
    },
  };

  test('round-trips an alert of every AlertKind', () {
    expect(factsByKind.keys.toSet(), AlertKind.values.toSet());
    for (final MapEntry(key: kind, value: facts) in factsByKind.entries) {
      final a = Alert(
        kind,
        Severity.danger,
        pondId: 'e1',
        batchId: 'l1',
        facts: facts,
      );
      final b = alertFromJson(alertToJson(a));
      expect(
        (b.kind, b.severity, b.pondId, b.batchId),
        (kind, Severity.danger, 'e1', 'l1'),
      );
      expect(b.facts, equals(facts), reason: '$kind');
    }
  });

  test('decoded facts keep the types the alert texts cast to', () {
    final b = alertFromJson(
      alertToJson(
        Alert(
          AlertKind.warningSignSeen,
          Severity.warning,
          facts: factsByKind[AlertKind.warningSignSeen]!,
        ),
      ),
    );
    expect(b.facts['signs'], isA<Set<WarningSign>>());
    final water = alertFromJson(
      alertToJson(
        Alert(
          AlertKind.waterOutOfRange,
          Severity.warning,
          facts: const {'param': WaterParam.ph, 'value': 9.0},
        ),
      ),
    );
    expect(water.facts['value'], isA<double>());
  });

  ReportContent full() => ReportContent(
    header: ReportHeader(
      siteName: 'Ambohidratrimo',
      visitDay: day,
      memberName: 'Hery',
      groupName: 'Rabe',
      periodFrom: DateTime.utc(2026, 3, 12, 21),
      periodTo: day,
      builtAt: DateTime.utc(2026, 3, 20, 7, 30),
    ),
    summary: 'Digue à reprendre.',
    pondCodes: const {'e1': 'E1'},
    batchCodes: const {'l1': 'L1'},
    alerts: [
      Alert(
        AlertKind.sampleDue,
        Severity.warning,
        pondId: 'e1',
        batchId: 'l1',
        facts: const {'daysSince': 15},
      ),
    ],
    health: [
      PondHealth(
        pondId: 'e1',
        deaths: 12,
        byObserver: const [
          ObserverDeaths(name: 'Rakoto', deaths: 9),
          ObserverDeaths(name: null, deaths: 3),
        ],
        signs: [
          DatedSigns(day, const {WarningSign.rubbing}),
        ],
        events: [
          HealthLine(
            at: day,
            signs: const {WarningSign.surfaceSwimming},
            suspectedIssue: 'Manque d\'oxygène',
            actions: const {HealthAction.isolated},
            photoKeys: const ['k1'],
          ),
        ],
        treatments: [
          TreatmentLine(
            at: day,
            batchId: 'l1',
            product: 'Sel',
            dose: '3 g/L',
            advisedBy: 'Technicien',
          ),
        ],
      ),
    ],
    water: [
      PondWater(
        pondId: 'e1',
        at: day,
        temperatureC: 27.5,
        ph: 7.2,
        oxygenMgL: 2.5,
        colour: WaterColour.darkGreen,
        issues: const [
          WaterIssue(
            WaterParam.oxygen,
            Severity.danger,
            value: 2.5,
            direction: Direction.low,
          ),
        ],
      ),
      const PondWater(pondId: 'e2'),
    ],
    growth: [
      BatchGrowth(
        batchId: 'l1',
        pondId: 'e1',
        avgWeightG: 30.5,
        weighedOn: day,
        liveCount: 980,
        biomassG: 29890,
        fcr: 1.5,
        trend: FcrTrend.worse,
        survival: 0.98,
      ),
      BatchGrowth(
        batchId: 'l1',
        pondId: 'e2',
        avgWeightG: 10,
        weighedOn: day,
        liveCount: 0,
        biomassG: 0,
        fcrNote: FcrNote.shared,
      ),
    ],
    feed: const [PondFeed(pondId: 'e1', feedG: 30000)],
    feedTotalG: 30000,
    next: [
      NextItem(kind: NextKind.sample, date: day, pondId: 'e1', batchId: 'l1'),
    ],
    observations: const [
      ReportObservation(
        pondId: 'e1',
        category: ObservationCategory.dike,
        ok: false,
        note: 'Fuite',
        photoKeys: ['k2'],
      ),
      ReportObservation(category: ObservationCategory.other, note: 'Vol'),
    ],
    visitPhotoKeys: const ['k3'],
  );

  test('round-trips a full content', () {
    final c = full();
    final back = ReportContent.fromJson(c.toJson());
    expect(back.toJson(), c.toJson());
    expect(back.header.visitDay, day);
    expect(back.health.single.byObserver.last.name, isNull);
    expect(back.health.single.events.single.actions, {HealthAction.isolated});
    expect(back.water.first.issues.single.direction, Direction.low);
    expect(back.growth.last.fcrNote, FcrNote.shared);
    expect(back.growth.first.trend, FcrTrend.worse);
    expect(back.alerts.single.facts, {'daysSince': 15});
  });

  test('survives encoding to a JSON string', () {
    final c = full();
    expect(ReportContent.decode(c.encode()).toJson(), c.toJson());
  });

  test('rejects format 2', () {
    final json = full().toJson()..['format'] = 2;
    expect(
      () => ReportContent.fromJson(json),
      throwsA(isA<UnsupportedReportFormat>()),
    );
  });
}
