import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/alerts/alert_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every kind leads to the screen that fixes it', () {
    String? route(AlertKind k, {Map<String, Object?> facts = const {}}) =>
        alertRoute(
          Alert(k, Severity.warning, pondId: 'e1', batchId: 'l1', facts: facts),
        );
    expect(route(AlertKind.waterOutOfRange), '/water/e1');
    expect(route(AlertKind.waterCheckDue), '/water/e1');
    expect(route(AlertKind.sampleDue), '/sample/e1?batchId=l1');
    expect(route(AlertKind.mortalitySpike), '/ponds/e1/problem');
    expect(route(AlertKind.warningSignSeen), '/ponds/e1/problem');
    expect(
      route(AlertKind.quarantineEnding),
      '/transfer?batchId=l1&fromPondId=e1',
    );
    expect(
      route(AlertKind.duplicateDailyLog, facts: {'date': DateTime(2026, 3, 9)}),
      '/ponds/e1/duplicates?date=2026-03-09',
    );
    for (final k in [
      AlertKind.fcrWorsening,
      AlertKind.growthStalled,
      AlertKind.densityOutOfRange,
      AlertKind.phaseChange,
      AlertKind.preHarvestFast,
    ]) {
      expect(route(k), '/ponds/e1', reason: '$k');
    }
    expect(route(AlertKind.prepStepDue), '/ponds/e1/prep');
    expect(
      alertRoute(const Alert(AlertKind.feedStockLow, Severity.warning)),
      '/more/feed',
    );
  });
}
