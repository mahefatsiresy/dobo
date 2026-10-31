import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/alerts/worker_advice.dart';
import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/domain/water.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;
  final today = DateTime(2026, 3, 20);
  DateTime d(int day) => farmDateToUtc(DateTime(2026, 3, day));

  LogFact log(int on, Set<WarningSign> signs, {String pond = 'e1'}) =>
      LogFact(id: '$pond$on', pondId: pond, date: d(on), signs: signs);

  Set<StopFeedingReason> reasons({
    List<Alert> alerts = const [],
    List<LogFact> logs = const [],
  }) => stopFeedingReasons(
    pondId: 'e1',
    alerts: alerts,
    logs: logs,
    today: today,
    config: cfg,
  );

  test('fast alert gives preHarvestFast', () {
    expect(
      reasons(
        alerts: [
          const Alert(AlertKind.preHarvestFast, Severity.warning, pondId: 'e1'),
        ],
      ),
      {StopFeedingReason.preHarvestFast},
    );
  });

  test('oxygen water alert gives lowOxygen, pH alert does not', () {
    Alert water(WaterParam p) => Alert(
      AlertKind.waterOutOfRange,
      Severity.warning,
      pondId: 'e1',
      facts: {'param': p},
    );
    expect(reasons(alerts: [water(WaterParam.oxygen)]), {
      StopFeedingReason.lowOxygen,
    });
    expect(reasons(alerts: [water(WaterParam.ph)]), isEmpty);
  });

  test('surface swimming yesterday gives distress, two days ago does not', () {
    expect(
      reasons(
        logs: [
          log(19, {WarningSign.surfaceSwimming}),
        ],
      ),
      {StopFeedingReason.distress},
    );
    expect(
      reasons(
        logs: [
          log(18, {WarningSign.erraticOrCircling}),
        ],
      ),
      isEmpty,
    );
  });

  test('other signs give no distress', () {
    expect(
      reasons(
        logs: [
          log(20, {WarningSign.rubbing}),
        ],
      ),
      isEmpty,
    );
  });

  test('future-dated sign gives distress', () {
    expect(
      reasons(
        logs: [
          log(25, {WarningSign.erraticOrCircling}),
        ],
      ),
      {StopFeedingReason.distress},
    );
  });

  test("other ponds' alerts and logs are ignored", () {
    expect(
      reasons(
        alerts: [
          const Alert(AlertKind.preHarvestFast, Severity.warning, pondId: 'e2'),
        ],
        logs: [
          log(20, {WarningSign.surfaceSwimming}, pond: 'e2'),
        ],
      ),
      isEmpty,
    );
  });

  test('nothing gives empty set', () {
    expect(reasons(), isEmpty);
  });
}
