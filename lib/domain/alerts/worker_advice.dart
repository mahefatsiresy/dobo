import '../config.dart';
import '../dates.dart';
import '../farm_facts.dart';
import '../types.dart';
import '../water.dart';
import 'alert.dart';

enum StopFeedingReason { preHarvestFast, lowOxygen, distress }

/// Fish behaving as if stressed or short of oxygen. DOMAIN §Feeding [5.3].
const distressSigns = {
  WarningSign.surfaceSwimming,
  WarningSign.erraticOrCircling,
};

/// Why the worker should not feed [pondId] today; empty when feeding is
/// fine. Future-dated signs count: a wrong phone clock must not hide them.
Set<StopFeedingReason> stopFeedingReasons({
  required String pondId,
  required List<Alert> alerts,
  required List<LogFact> logs,
  required DateTime today,
  required DomainConfig config,
}) => {
  for (final a in alerts)
    if (a.pondId == pondId) ...[
      if (a.kind == AlertKind.preHarvestFast) StopFeedingReason.preHarvestFast,
      if (a.kind == AlertKind.waterOutOfRange &&
          a.facts['param'] == WaterParam.oxygen)
        StopFeedingReason.lowOxygen,
    ],
  for (final l in logs)
    if (l.pondId == pondId &&
        l.signs.any(distressSigns.contains) &&
        daysBetween(l.date, today) < config.stopFeedingSignDays)
      StopFeedingReason.distress,
};
