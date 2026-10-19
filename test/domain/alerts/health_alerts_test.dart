import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/alerts/health_alerts.dart';
import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/fcr.dart';
import 'package:dobo/domain/stock.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/domain/water.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;
  final today = DateTime(2026, 3, 10);

  test('one water alert per issue, keeping its severity', () {
    expect(
      waterAlerts(
        pondId: 'E1',
        issues: const [
          WaterIssue(
            WaterParam.oxygen,
            Severity.danger,
            value: 2,
            direction: Direction.low,
          ),
        ],
      ).single.severity,
      Severity.danger,
    );
    expect(waterAlerts(pondId: 'E1', issues: const []), isEmpty);
  });

  test('FCR worsening and growth stalled', () {
    List<FcrResult> f(List<double> xs) => [for (final x in xs) FcrValue(x)];
    expect(
      fcrWorseningAlert(
        pondId: 'E1',
        batchId: 'L1',
        periodFcrs: f([1.5, 1.6, 1.7]),
      )!.severity,
      Severity.danger,
    );
    expect(
      fcrWorseningAlert(pondId: 'E1', batchId: 'L1', periodFcrs: f([1.7, 1.6])),
      isNull,
    );
    expect(
      growthStalledAlert(
        pondId: 'E1',
        batchId: 'L1',
        latest: const FcrStalled(),
      )!.kind,
      AlertKind.growthStalled,
    );
    expect(
      growthStalledAlert(
        pondId: 'E1',
        batchId: 'L1',
        latest: const FcrValue(1.6),
      ),
      isNull,
    );
  });

  test('mortality spike', () {
    Alert? m(int today, List<int> prev, int live) => mortalitySpikeAlert(
      pondId: 'E1',
      deathsToday: today,
      previousDailyDeaths: prev,
      liveCountAtDayStart: live,
      config: cfg,
    );
    expect(m(51, List.filled(7, 5), 10000), isNotNull); // > 0.5 % of 10 000
    expect(m(15, List.filled(7, 5), 10000), isNotNull); // 3 × average 5
    expect(m(14, List.filled(7, 5), 10000), isNull);
    expect(
      m(3, List.filled(7, 0), 10000),
      isNull,
    ); // zero average never multiplies
    expect(m(5, const [], 100), isNotNull); // 5 > 0.5, meets the minimum
    expect(m(4, const [], 100), isNull); // below the 5-death minimum
    expect(m(1, const [0, 0, 0, 0, 0, 0, 1], 10000), isNull); // routine loss
    expect(
      m(15, [100, ...List.filled(7, 5)], 10000),
      isNotNull,
    ); // last 7 days only
  });

  test('warning signs within the last 3 days', () {
    Alert? s(DateTime date, Set<WarningSign> signs) => warningSignAlert(
      pondId: 'E1',
      today: today,
      config: cfg,
      recent: [DatedSigns(date, signs)],
    );
    expect(s(DateTime(2026, 3, 8), {WarningSign.rubbing})!.facts['signs'], {
      WarningSign.rubbing,
    });
    expect(s(DateTime(2026, 3, 7), {WarningSign.rubbing}), isNull);
    expect(s(DateTime(2026, 3, 9), const {}), isNull);
    // A wrong phone clock must not hide a sign.
    expect(s(DateTime(2026, 3, 12), {WarningSign.whiteSpots}), isNotNull);
  });

  test('density out of range', () {
    expect(
      densityAlert(
        pondId: 'E1',
        status: DensityStatus.above,
        density: 7,
      )!.severity,
      Severity.warning,
    );
    expect(
      densityAlert(pondId: 'E1', status: DensityStatus.within, density: 4),
      isNull,
    );
    expect(densityAlert(pondId: 'E1', status: null), isNull);
  });

  test('phase change', () {
    final p = phaseChangeAlert(
      pondId: 'E1',
      batchId: 'L1',
      previousAvgG: 18,
      latestAvgG: 22,
      config: cfg,
    )!;
    expect((p.facts['from'], p.facts['to']), (Phase.pregrow, Phase.growout));
    expect(
      phaseChangeAlert(
        pondId: 'E1',
        batchId: 'L1',
        latestAvgG: 22,
        config: cfg,
      ),
      isNull,
    );
    expect(
      phaseChangeAlert(
        pondId: 'E1',
        batchId: 'L1',
        previousAvgG: 22,
        latestAvgG: 30,
        config: cfg,
      ),
      isNull,
    );
  });
}
