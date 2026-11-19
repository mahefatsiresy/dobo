import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/attention_band.dart';
import '../ponds/pond_attention.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/alerts/alert.dart';
import '../../domain/alerts/farm_alerts.dart';
import '../../domain/alerts/worker_advice.dart';
import '../../domain/pond.dart';
import '../../domain/types.dart';
import '../common/farm_today.dart';
import '../feed/feed_providers.dart';
import '../prep/prep_providers.dart';
import '../ponds/pond_overview.dart';

/// Each pond's latest water reading.
final latestReadingsProvider = StreamProvider<Map<String, WaterReading>>(
  (ref) => ref.watch(readingRepositoryProvider).watchLatestWaterReadings(),
);

/// Health events recent enough to raise "warning sign seen".
final _recentHealthProvider = StreamProvider<List<HealthEvent>>((ref) {
  final today = ref.watch(farmTodayProvider);
  final back = ref.watch(domainConfigProvider).warningSignLookbackDays;
  return ref
      .watch(healthRepositoryProvider)
      .watchSince(DateTime(today.year, today.month, today.day - back));
});

/// Every open alert and due task on the active ponds, sorted (SPEC F7).
final alertsProvider = Provider<AsyncValue<List<Alert>>>((ref) {
  final facts = ref.watch(farmFactsProvider);
  final ponds = ref.watch(pondsProvider);
  final summaries = ref.watch(batchSummariesProvider);
  final readings = ref.watch(latestReadingsProvider);
  final health = ref.watch(_recentHealthProvider);
  final feed = ref.watch(feedStockProvider);
  final prep = ref.watch(prepProgressAllProvider);
  if (!facts.hasValue ||
      !ponds.hasValue ||
      !summaries.hasValue ||
      !readings.hasValue ||
      !health.hasValue ||
      !feed.hasValue ||
      !prep.hasValue) {
    return const AsyncLoading();
  }
  // Recomputed at the farm's midnight and when the app comes back.
  ref.watch(farmTodayProvider);
  final now = ref.watch(clockProvider)().toUtc();
  final config = ref.watch(domainConfigProvider);
  final batchInfos = {
    for (final s in summaries.requireValue)
      s.batch.id: BatchInfo(
        id: s.batch.id,
        status: s.batch.status,
        plannedHarvestOn: s.batch.plannedHarvestOn,
      ),
  };
  // A fast opens or closes at a set hour, not when a record changes.
  final next = nextTimedChange(
    batches: batchInfos.values,
    now: now,
    config: config,
  );
  if (next != null) {
    final timer = Timer(
      next.difference(now) + const Duration(seconds: 1),
      ref.invalidateSelf,
    );
    ref.onDispose(timer.cancel);
  }
  return AsyncData(
    farmAlerts(
      facts: facts.requireValue,
      ponds: [
        for (final p in ponds.requireValue)
          PondInfo(
            id: p.id,
            code: p.code,
            structure: p.structure,
            surfaceM2: pondSurfaceM2(
              lengthM: p.lengthM,
              widthM: p.widthM,
              overrideM2: p.surfaceM2Override,
            ),
          ),
      ],
      batches: batchInfos,
      latestReadings: {
        for (final MapEntry(key: pondId, value: r)
            in readings.requireValue.entries)
          pondId: ReadingInfo(
            at: r.recordedAt,
            temperatureC: r.temperatureC,
            ph: r.ph,
            oxygenMgL: r.oxygenMgL,
            colour: r.colour,
          ),
      },
      healthSigns: [
        for (final e in health.requireValue)
          if (e.signs.isNotEmpty)
            PondSigns(e.pondId, DatedSigns(e.recordedAt, e.signs)),
      ],
      feedStock: feed.requireValue,
      prep: prep.requireValue,
      now: now,
      config: config,
    ),
  );
});

/// One pond's alerts; empty while loading.
final pondAlertsProvider = Provider.family<List<Alert>, String>(
  (ref, pondId) => [
    for (final a in ref.watch(alertsProvider).value ?? const <Alert>[])
      if (a.pondId == pondId) a,
  ],
);

/// Ponds whose band is danger, and farm-wide danger alerts: one count for
/// the Alerts badge, its "Danger" heading and the ponds list's line
/// (docs/design.md §Step 4).
final dangerPondsProvider = Provider<({int ponds, int farmWide})>((ref) {
  final alertsValue = ref.watch(alertsProvider);
  final overviewsValue = ref.watch(pondOverviewsProvider);
  // Nothing until both are known: isolated ponds arrive before the alerts,
  // and a partial count would read as a smaller danger.
  if (!alertsValue.hasValue || !overviewsValue.hasValue) {
    return (ponds: 0, farmWide: 0);
  }
  final alerts = alertsValue.requireValue;
  final overviews = overviewsValue.requireValue;
  var ponds = 0;
  for (final o in overviews) {
    final a = pondAttention(o, [
      for (final x in alerts)
        if (x.pondId == o.pond.id) x,
    ]);
    if (a?.severity == BandSeverity.danger) ponds++;
  }
  final farmWide = alerts
      .where((a) => a.pondId == null && a.severity == Severity.danger)
      .length;
  return (ponds: ponds, farmWide: farmWide);
});

/// Why the worker should not feed a pond today (DOMAIN §Feeding).
final stopFeedingProvider = Provider.family<Set<StopFeedingReason>, String>((
  ref,
  pondId,
) {
  final alerts = ref.watch(alertsProvider).value;
  final facts = ref.watch(farmFactsProvider).value;
  if (alerts == null || facts == null) return const {};
  return stopFeedingReasons(
    pondId: pondId,
    alerts: alerts,
    logs: facts.logs,
    today: ref.watch(farmTodayProvider),
    config: ref.watch(domainConfigProvider),
  );
});
