import '../config.dart';
import '../dates.dart';
import '../farm_facts.dart';
import '../growth.dart';
import '../stock.dart';
import '../types.dart';
import '../water.dart';
import 'alert.dart';
import 'health_alerts.dart';
import 'schedule_alerts.dart';

/// What the alerts need to know about a pond.
class PondInfo {
  const PondInfo({
    required this.id,
    required this.code,
    required this.structure,
    required this.surfaceM2,
  });

  final String id;
  final String code;
  final StructureType structure;
  final double? surfaceM2;
}

class BatchInfo {
  const BatchInfo({
    required this.id,
    required this.status,
    this.plannedHarvestOn,
  });

  final String id;
  final BatchStatus status;

  /// A hand-entered date.
  final DateTime? plannedHarvestOn;
}

/// A pond's latest water reading.
class ReadingInfo {
  const ReadingInfo({
    required this.at,
    this.temperatureC,
    this.ph,
    this.oxygenMgL,
    this.colour,
  });

  final DateTime at;
  final double? temperatureC;
  final double? ph;
  final double? oxygenMgL;
  final WaterColour? colour;
}

/// Signs recorded for a pond outside daily logs (health events).
class PondSigns {
  const PondSigns(this.pondId, this.signs);

  final String pondId;
  final DatedSigns signs;
}

/// Every open alert and due task for [ponds] (the active ones), sorted by
/// [compareAlerts]. DOMAIN §Alert rules. Feed stock, feed age and pond
/// prep need records that arrive in M7.
List<Alert> farmAlerts({
  required FarmFacts facts,
  required List<PondInfo> ponds,
  required Map<String, BatchInfo> batches,
  required Map<String, ReadingInfo> latestReadings,
  List<PondSigns> healthSigns = const [],
  required DateTime now,
  required DomainConfig config,
}) {
  final today = farmDate(now);
  final placements = placementsOf(facts);
  final out = <Alert>[];
  void add(Alert? a) {
    if (a != null) out.add(a);
  }

  for (final pond in ponds) {
    final here = [
      for (final p in placements)
        if (p.pondId == pond.id && (p.live.count > 0 || p.live.inconsistent)) p,
    ];
    final logs = [
      for (final l in facts.logs)
        if (l.pondId == pond.id) l,
    ];
    final live = here.fold(0, (n, p) => n + p.live.count);
    final stocked = here.isNotEmpty;

    if (stocked) {
      final reading = latestReadings[pond.id];
      out.addAll(
        waterAlerts(
          pondId: pond.id,
          issues: waterIssues(
            temperatureC: reading?.temperatureC,
            ph: reading?.ph,
            oxygenMgL: reading?.oxygenMgL,
            colour: _colour(reading, logs),
            config: config,
          ),
        ),
      );
      add(
        waterCheckDueAlert(
          pondId: pond.id,
          lastReading: reading?.at,
          today: today,
          config: config,
        ),
      );
      final density = densityPerM2(live: live, surfaceM2: pond.surfaceM2);
      if (live > 0) {
        add(
          densityAlert(
            pondId: pond.id,
            status: densityStatus(
              density: density,
              structure: pond.structure,
              config: config,
            ),
            density: density,
          ),
        );
      }
    }

    add(_mortalitySpike(facts, pond.id, logs, today, config));
    add(
      warningSignAlert(
        pondId: pond.id,
        recent: [
          for (final l in logs)
            if (l.signs.isNotEmpty) DatedSigns(l.date, l.signs),
          for (final h in healthSigns)
            if (h.pondId == pond.id) h.signs,
        ],
        today: today,
        config: config,
      ),
    );

    for (final p in here) {
      final batch = batches[p.batchId];
      if (batch == null || batch.status == BatchStatus.closed) continue;
      out.addAll(_batchAlerts(facts, pond, batch, logs, today, now, config));
    }
  }

  final shown = {for (final p in ponds) p.id};
  out.addAll(
    duplicateLogAlerts(facts.logs).where((a) => shown.contains(a.pondId)),
  );

  final codes = {for (final p in ponds) p.id: p.code};
  return out..sort((a, b) => compareAlerts(a, b, codes));
}

/// The colour to judge: the latest daily log's when it is from a later day
/// than the reading, or the reading has none.
WaterColour? _colour(ReadingInfo? reading, List<LogFact> logs) {
  LogFact? latest;
  for (final l in logs) {
    if (l.waterColour != null &&
        (latest == null || !l.date.isBefore(latest.date))) {
      latest = l;
    }
  }
  if (latest == null) return reading?.colour;
  if (reading == null ||
      reading.colour == null ||
      daysBetween(reading.at, latest.date) > 0) {
    return latest.waterColour;
  }
  return reading.colour;
}

/// The most recent day in the last `mortalityLookbackDays` that spiked,
/// with its date in the facts.
Alert? _mortalitySpike(
  FarmFacts facts,
  String pondId,
  List<LogFact> logs,
  DateTime today,
  DomainConfig config,
) {
  if (!logs.any((l) => l.deaths > 0)) return null;
  for (var back = 0; back < config.mortalityLookbackDays; back++) {
    final day = DateTime(today.year, today.month, today.day - back);
    final trailing = dailyDeaths(
      facts,
      pondId,
      from: DateTime(
        day.year,
        day.month,
        day.day - config.mortalityTrailingDays,
      ),
      to: DateTime(day.year, day.month, day.day),
    );
    final alert = mortalitySpikeAlert(
      pondId: pondId,
      deathsToday: trailing.last,
      previousDailyDeaths: trailing.sublist(0, trailing.length - 1),
      liveCountAtDayStart: liveInPondAtDayStart(facts, pondId, day),
      config: config,
    );
    if (alert != null) {
      return Alert(
        alert.kind,
        alert.severity,
        pondId: pondId,
        facts: {...alert.facts, 'date': day},
      );
    }
  }
  return null;
}

List<Alert> _batchAlerts(
  FarmFacts facts,
  PondInfo pond,
  BatchInfo batch,
  List<LogFact> logs,
  DateTime today,
  DateTime now,
  DomainConfig config,
) {
  final points = weighPoints(facts, batchId: batch.id, pondId: pond.id);
  final periods = fcrPeriods(facts, batchId: batch.id, pondId: pond.id);
  final values = [
    for (final p in periods)
      if (p.fcr != null) p.fcr!,
  ];
  final latestFcr = periods.isEmpty ? null : periods.last.fcr;

  DateTime? quarantineStart;
  for (final s in facts.stockings) {
    if (s.batchId == batch.id &&
        (quarantineStart == null || s.date.isBefore(quarantineStart))) {
      quarantineStart = s.date;
    }
  }

  DateTime? lastFeedingAt;
  for (final l in logs) {
    if (l.feedG > 0 &&
        (lastFeedingAt == null || l.date.isAfter(lastFeedingAt))) {
      lastFeedingAt = l.date;
    }
  }

  return [
    if (values.isNotEmpty)
      ?fcrWorseningAlert(
        pondId: pond.id,
        batchId: batch.id,
        periodFcrs: values,
      ),
    if (latestFcr != null)
      ?growthStalledAlert(
        pondId: pond.id,
        batchId: batch.id,
        latest: latestFcr,
      ),
    if (points.length >= 2 && points.last.fromSample)
      ?phaseChangeAlert(
        pondId: pond.id,
        batchId: batch.id,
        previousAvgG: points[points.length - 2].avgWeightG,
        latestAvgG: points.last.avgWeightG,
        config: config,
      ),
    if (points.isNotEmpty)
      ?sampleDueAlert(
        pondId: pond.id,
        batchId: batch.id,
        lastSampleOrStocking: points.last.date,
        today: today,
        config: config,
      ),
    if (batch.status == BatchStatus.quarantine && quarantineStart != null)
      ?quarantineEndingAlert(
        pondId: pond.id,
        batchId: batch.id,
        quarantineStart: quarantineStart,
        today: today,
        config: config,
      ),
    if (batch.plannedHarvestOn != null)
      ?preHarvestFastAlert(
        pondId: pond.id,
        batchId: batch.id,
        plannedHarvestAt: plannedHarvestAt(batch.plannedHarvestOn!, config),
        now: now,
        lastFeedingAt: lastFeedingAt,
        config: config,
      ),
  ];
}

/// When a harvest planned for the farm date [plannedHarvestOn] starts:
/// `harvestHour` that morning (DOMAIN §Harvest and delivery).
DateTime plannedHarvestAt(DateTime plannedHarvestOn, DomainConfig config) =>
    farmTimeToUtc(farmDate(plannedHarvestOn), config.harvestHour, 0);

/// The next moment after [now] an alert changes with no new record: a
/// pre-harvest fast opening or closing. Null when none is coming.
DateTime? nextTimedChange({
  required Iterable<BatchInfo> batches,
  required DateTime now,
  required DomainConfig config,
}) {
  DateTime? next;
  for (final b in batches) {
    final on = b.plannedHarvestOn;
    if (on == null || b.status == BatchStatus.closed) continue;
    final at = plannedHarvestAt(on, config);
    for (final t in [
      at.subtract(Duration(hours: config.preHarvestFastHours)),
      at,
    ]) {
      if (t.isAfter(now) && (next == null || t.isBefore(next))) next = t;
    }
  }
  return next;
}

/// One alert per pond-day with more than one current log; facts carry the
/// farm `date` and the `logIds` in list order.
List<Alert> duplicateLogAlerts(List<LogFact> logs) {
  final byDay = <(String, DateTime), List<String>>{};
  for (final l in logs) {
    (byDay[(l.pondId, farmDate(l.date))] ??= []).add(l.id);
  }
  return [
    for (final MapEntry(key: (pondId, day), value: ids) in byDay.entries)
      if (ids.length > 1)
        Alert(
          AlertKind.duplicateDailyLog,
          Severity.warning,
          pondId: pondId,
          facts: {'date': day, 'logIds': ids},
        ),
  ];
}

/// Danger first; then by kind, in DOMAIN table order; then by pond code
/// (alerts without a pond last); then by batch.
int compareAlerts(Alert a, Alert b, Map<String, String> pondCodes) {
  final bySeverity = b.severity.index.compareTo(a.severity.index);
  if (bySeverity != 0) return bySeverity;
  final byKind = _kindOrder
      .indexOf(a.kind)
      .compareTo(_kindOrder.indexOf(b.kind));
  if (byKind != 0) return byKind;
  final ca = pondCodes[a.pondId], cb = pondCodes[b.pondId];
  if (ca != cb) {
    if (ca == null) return 1;
    if (cb == null) return -1;
    final byCode = ca.compareTo(cb);
    if (byCode != 0) return byCode;
  }
  return (a.batchId ?? '').compareTo(b.batchId ?? '');
}

/// DOMAIN §Alert rules table order, duplicate pond-days last.
const _kindOrder = [
  AlertKind.waterOutOfRange,
  AlertKind.fcrWorsening,
  AlertKind.growthStalled,
  AlertKind.mortalitySpike,
  AlertKind.warningSignSeen,
  AlertKind.sampleDue,
  AlertKind.waterCheckDue,
  AlertKind.densityOutOfRange,
  AlertKind.phaseChange,
  AlertKind.quarantineEnding,
  AlertKind.preHarvestFast,
  AlertKind.feedStockLow,
  AlertKind.feedTooOld,
  AlertKind.prepStepDue,
  AlertKind.duplicateDailyLog,
];
