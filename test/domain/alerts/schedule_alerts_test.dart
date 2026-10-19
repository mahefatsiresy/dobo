import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/alerts/schedule_alerts.dart';
import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;
  final d0 = DateTime(2026, 3, 1);
  DateTime d(int days) => d0.add(Duration(days: days));

  test('sample due after 14 days', () {
    Alert? s(int days) => sampleDueAlert(
      pondId: 'E1',
      batchId: 'L1',
      lastSampleOrStocking: d0,
      today: d(days),
      config: cfg,
    );
    expect(s(13), isNull);
    expect(s(14)!.facts['daysSince'], 14);
  });

  test('water check due when never read or 7 days old', () {
    expect(waterCheckDueAlert(pondId: 'E1', today: d0, config: cfg), isNotNull);
    expect(
      waterCheckDueAlert(
        pondId: 'E1',
        lastReading: d0,
        today: d(6),
        config: cfg,
      ),
      isNull,
    );
    expect(
      waterCheckDueAlert(
        pondId: 'E1',
        lastReading: d0,
        today: d(7),
        config: cfg,
      ),
      isNotNull,
    );
  });

  test('quarantine ending from day 7, recommended by day 10', () {
    Alert? q(int days) => quarantineEndingAlert(
      pondId: 'Q1',
      batchId: 'L1',
      quarantineStart: d0,
      today: d(days),
      config: cfg,
    );
    expect(q(6), isNull);
    expect((q(7)!.facts['days'], q(7)!.facts['recommendedDays']), (7, 10));
  });

  test('pre-harvest fast in the 48 h before harvest', () {
    final harvest = DateTime(2026, 3, 10, 6);
    Alert? h(DateTime now, [DateTime? fed]) => preHarvestFastAlert(
      pondId: 'E1',
      batchId: 'L1',
      plannedHarvestAt: harvest,
      now: now,
      lastFeedingAt: fed,
      config: cfg,
    );
    expect(h(DateTime(2026, 3, 8, 5, 59)), isNull);
    expect(h(DateTime(2026, 3, 8, 6))!.facts['fedDuringFast'], isFalse);
    expect(
      h(
        DateTime(2026, 3, 9, 8),
        DateTime(2026, 3, 8, 15),
      )!.facts['fedDuringFast'],
      isTrue,
    );
    expect(
      h(
        DateTime(2026, 3, 9, 8),
        DateTime(2026, 3, 7, 15),
      )!.facts['fedDuringFast'],
      isFalse,
    );
    expect(h(harvest), isNull);
  });

  test('feed stock low under 7 days', () {
    expect(
      feedStockLowAlert(stockG: 60000, dailyUsageG: 10000, config: cfg),
      isNotNull,
    );
    expect(
      feedStockLowAlert(stockG: 70000, dailyUsageG: 10000, config: cfg),
      isNull,
    );
    expect(feedStockLowAlert(stockG: 0, dailyUsageG: 0, config: cfg), isNull);
  });

  test('feed too old', () {
    Alert? f(int days, {int remaining = 5000}) => feedTooOldAlert(
      feedLotId: 'F1',
      manufacturedOn: d0,
      remainingG: remaining,
      today: d(days),
      config: cfg,
    );
    expect(f(60)!.severity, Severity.warning);
    expect(f(90)!.severity, Severity.danger);
    expect(f(90, remaining: 0), isNull);
    expect(f(59), isNull);
  });

  test('prep step waiting time elapsed', () {
    Alert? p(PrepStep step, int days) => prepStepDueAlert(
      pondId: 'E1',
      lastDone: step,
      lastDoneOn: d0,
      today: d(days),
      config: cfg,
    );
    expect(p(PrepStep.drain, 4), isNull);
    expect(p(PrepStep.drain, 5)!.facts['waitingStep'], PrepStep.dry);
    expect(p(PrepStep.fill, 2)!.facts['waitingStep'], PrepStep.rest);
    expect(p(PrepStep.treat, 30), isNull);
  });
}
