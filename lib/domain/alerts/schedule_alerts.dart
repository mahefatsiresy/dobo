import '../config.dart';
import '../dates.dart';
import '../feed_stock.dart';
import '../types.dart';
import 'alert.dart';

Alert? sampleDueAlert({
  required String pondId,
  required String batchId,
  required DateTime lastSampleOrStocking,
  required DateTime today,
  required DomainConfig config,
}) {
  final days = daysBetween(lastSampleOrStocking, today);
  if (days < config.sampleIntervalDays) return null;
  return Alert(
    AlertKind.sampleDue,
    Severity.warning,
    pondId: pondId,
    batchId: batchId,
    facts: {'daysSince': days},
  );
}

Alert? waterCheckDueAlert({
  required String pondId,
  DateTime? lastReading,
  required DateTime today,
  required DomainConfig config,
}) {
  if (lastReading != null &&
      daysBetween(lastReading, today) < config.waterCheckIntervalDays) {
    return null;
  }
  return Alert(AlertKind.waterCheckDue, Severity.warning, pondId: pondId);
}

Alert? quarantineEndingAlert({
  required String pondId,
  required String batchId,
  required DateTime quarantineStart,
  required DateTime today,
  required DomainConfig config,
}) {
  final days = daysBetween(quarantineStart, today);
  if (days < config.quarantineDays.min) return null;
  return Alert(
    AlertKind.quarantineEnding,
    Severity.warning,
    pondId: pondId,
    batchId: batchId,
    facts: {'days': days, 'recommendedDays': config.quarantineDays.max},
  );
}

/// Fires through the fasting window before a planned harvest, so the worker
/// knows not to feed. DOMAIN §Alert rules.
Alert? preHarvestFastAlert({
  required String pondId,
  required String batchId,
  required DateTime plannedHarvestAt,
  required DateTime now,
  DateTime? lastFeedingAt,
  required DomainConfig config,
}) {
  final windowStart = plannedHarvestAt.subtract(
    Duration(hours: config.preHarvestFastHours),
  );
  if (now.isBefore(windowStart) || !now.isBefore(plannedHarvestAt)) {
    return null;
  }
  final fed = lastFeedingAt != null && !lastFeedingAt.isBefore(windowStart);
  return Alert(
    AlertKind.preHarvestFast,
    Severity.warning,
    pondId: pondId,
    batchId: batchId,
    facts: {'fedDuringFast': fed},
  );
}

Alert? feedStockLowAlert({
  required int stockG,
  required int dailyUsageG,
  required DomainConfig config,
}) {
  final days = daysOfStockLeft(stockG: stockG, dailyUsageG: dailyUsageG);
  if (days == null || days >= config.lowStockDays) return null;
  return Alert(
    AlertKind.feedStockLow,
    Severity.warning,
    facts: {'daysLeft': days},
  );
}

Alert? feedTooOldAlert({
  required String feedLotId,
  required DateTime manufacturedOn,
  required int remainingG,
  required DateTime today,
  required DomainConfig config,
}) {
  if (remainingG <= 0) return null;
  final age = feedLotAge(
    manufacturedOn: manufacturedOn,
    today: today,
    config: config,
  );
  final severity = switch (age) {
    FeedAge.ok => null,
    FeedAge.old => Severity.warning,
    FeedAge.expired => Severity.danger,
  };
  if (severity == null) return null;
  return Alert(
    AlertKind.feedTooOld,
    severity,
    facts: {'feedLotId': feedLotId, 'age': age},
  );
}

/// After draining, the pond dries; after filling, it rests. Fires once the
/// minimum waiting time has passed. DOMAIN §Pond preparation.
Alert? prepStepDueAlert({
  required String pondId,
  required PrepStep lastDone,
  required DateTime lastDoneOn,
  required DateTime today,
  required DomainConfig config,
}) {
  final (waiting, minDays) = switch (lastDone) {
    PrepStep.drain => (PrepStep.dry, config.dryingDays.min),
    PrepStep.fill => (PrepStep.rest, config.restDays.min),
    _ => (null, 0),
  };
  if (waiting == null || daysBetween(lastDoneOn, today) < minDays) return null;
  return Alert(
    AlertKind.prepStepDue,
    Severity.warning,
    pondId: pondId,
    facts: {'waitingStep': waiting},
  );
}
