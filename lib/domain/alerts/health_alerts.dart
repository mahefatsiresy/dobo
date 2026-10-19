import '../config.dart';
import '../dates.dart';
import '../fcr.dart';
import '../phase.dart';
import '../stock.dart';
import '../types.dart';
import '../water.dart';
import 'alert.dart';

List<Alert> waterAlerts({
  required String pondId,
  required List<WaterIssue> issues,
}) => [
  for (final i in issues)
    Alert(
      AlertKind.waterOutOfRange,
      i.severity,
      pondId: pondId,
      facts: {'param': i.param, 'value': i.value, 'direction': i.direction},
    ),
];

Alert? fcrWorseningAlert({
  required String pondId,
  required String batchId,
  required List<FcrResult> periodFcrs,
}) => isFcrWorsening(periodFcrs)
    ? Alert(
        AlertKind.fcrWorsening,
        Severity.danger,
        pondId: pondId,
        batchId: batchId,
      )
    : null;

Alert? growthStalledAlert({
  required String pondId,
  required String batchId,
  required FcrResult latest,
}) => latest is FcrStalled
    ? Alert(
        AlertKind.growthStalled,
        Severity.danger,
        pondId: pondId,
        batchId: batchId,
      )
    : null;

/// [previousDailyDeaths] is chronological, one entry per day, 0 for days
/// without deaths; only the last `mortalityTrailingDays` count.
Alert? mortalitySpikeAlert({
  required String pondId,
  required int deathsToday,
  required List<int> previousDailyDeaths,
  required int liveCountAtDayStart,
  required DomainConfig config,
}) {
  final n = config.mortalityTrailingDays;
  final window = previousDailyDeaths.length > n
      ? previousDailyDeaths.sublist(previousDailyDeaths.length - n)
      : previousDailyDeaths;
  final average = window.isEmpty
      ? 0.0
      : window.reduce((a, b) => a + b) / window.length;
  final overShare =
      deathsToday > liveCountAtDayStart * config.mortalitySpikeShare;
  final overAverage =
      average > 0 && deathsToday >= config.mortalitySpikeMultiplier * average;
  if (!overShare && !overAverage) return null;
  return Alert(
    AlertKind.mortalitySpike,
    Severity.danger,
    pondId: pondId,
    facts: {'deathsToday': deathsToday, 'trailingAverage': average},
  );
}

Alert? warningSignAlert({
  required String pondId,
  required List<DatedSigns> recent,
  required DateTime today,
  required DomainConfig config,
}) {
  final signs = <WarningSign>{
    for (final r in recent)
      if (daysBetween(r.date, today) case final d
          when d >= 0 && d < config.warningSignLookbackDays)
        ...r.signs,
  };
  if (signs.isEmpty) return null;
  return Alert(
    AlertKind.warningSignSeen,
    Severity.danger,
    pondId: pondId,
    facts: {'signs': signs},
  );
}

Alert? densityAlert({
  required String pondId,
  required DensityStatus? status,
  double? density,
}) => status == DensityStatus.below || status == DensityStatus.above
    ? Alert(
        AlertKind.densityOutOfRange,
        Severity.warning,
        pondId: pondId,
        facts: {'status': status, 'density': density},
      )
    : null;

Alert? phaseChangeAlert({
  required String pondId,
  required String batchId,
  double? previousAvgG,
  required double latestAvgG,
  required DomainConfig config,
}) {
  if (previousAvgG == null) return null;
  final from = phaseFor(previousAvgG, config);
  final to = phaseFor(latestAvgG, config);
  if (from == to) return null;
  return Alert(
    AlertKind.phaseChange,
    Severity.warning,
    pondId: pondId,
    batchId: batchId,
    facts: {'from': from, 'to': to},
  );
}
