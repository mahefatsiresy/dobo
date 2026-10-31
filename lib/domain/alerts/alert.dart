import '../types.dart';

enum AlertKind {
  waterOutOfRange,
  fcrWorsening,
  growthStalled,
  mortalitySpike,
  warningSignSeen,
  densityOutOfRange,
  phaseChange,
  sampleDue,
  waterCheckDue,
  quarantineEnding,
  preHarvestFast,
  feedStockLow,
  feedTooOld,
  prepStepDue,

  /// Two current daily logs for one pond-day, from two phones (SPEC §7).
  duplicateDailyLog,
}

/// A computed alert. [facts] carry the values the UI needs to word it; the
/// text itself comes from the ARB files. DOMAIN §Alert rules.
class Alert {
  const Alert(
    this.kind,
    this.severity, {
    this.pondId,
    this.batchId,
    this.facts = const {},
  });

  final AlertKind kind;
  final Severity severity;
  final String? pondId;
  final String? batchId;
  final Map<String, Object?> facts;
}

class DatedSigns {
  const DatedSigns(this.date, this.signs);

  final DateTime date;
  final Set<WarningSign> signs;
}
