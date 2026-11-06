import '../../domain/alerts/alert.dart';

/// The screen that resolves [a] (SPEC F7); null when there is none yet.
String? alertRoute(Alert a) {
  final pond = a.pondId;
  final batch = a.batchId;
  if (pond == null) return null;
  return switch (a.kind) {
    AlertKind.waterOutOfRange || AlertKind.waterCheckDue => '/water/$pond',
    AlertKind.sampleDue => '/sample/$pond?batchId=$batch',
    AlertKind.mortalitySpike ||
    AlertKind.warningSignSeen => '/ponds/$pond/problem',
    AlertKind.quarantineEnding => '/transfer?batchId=$batch&fromPondId=$pond',
    AlertKind.duplicateDailyLog =>
      '/ponds/$pond/duplicates?date=${_day(a.facts['date']! as DateTime)}',
    AlertKind.fcrWorsening ||
    AlertKind.growthStalled ||
    AlertKind.densityOutOfRange ||
    AlertKind.phaseChange ||
    AlertKind.preHarvestFast => '/ponds/$pond',
    AlertKind.prepStepDue => '/ponds/$pond/prep',
    AlertKind.feedStockLow || AlertKind.feedTooOld => null,
  };
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
