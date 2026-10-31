import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/alerts/alert.dart';
import '../../domain/alerts/farm_alerts.dart';
import '../../domain/alerts/worker_advice.dart';
import '../../domain/pond.dart';
import '../../domain/types.dart';
import '../common/farm_today.dart';
import '../ponds/pond_overview.dart';

final _latestReadingsProvider = StreamProvider<Map<String, WaterReading>>(
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
  final readings = ref.watch(_latestReadingsProvider);
  final health = ref.watch(_recentHealthProvider);
  if (!facts.hasValue ||
      !ponds.hasValue ||
      !summaries.hasValue ||
      !readings.hasValue ||
      !health.hasValue) {
    return const AsyncLoading();
  }
  // Recomputed at the farm's midnight and when the app comes back.
  ref.watch(farmTodayProvider);
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
      batches: {
        for (final s in summaries.requireValue)
          s.batch.id: BatchInfo(
            id: s.batch.id,
            status: s.batch.status,
            plannedHarvestOn: s.batch.plannedHarvestOn,
          ),
      },
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
      now: ref.watch(clockProvider)().toUtc(),
      config: ref.watch(domainConfigProvider),
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

/// Danger alerts, counted on the Alerts tab.
final dangerCountProvider = Provider<int>(
  (ref) => (ref.watch(alertsProvider).value ?? const <Alert>[])
      .where((a) => a.severity == Severity.danger)
      .length,
);

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
