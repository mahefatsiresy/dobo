import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/providers.dart';
import '../../domain/alerts/farm_alerts.dart';
import '../../domain/exports/register.dart';
import '../../domain/exports/weekly.dart';
import '../../domain/report/report_content.dart';
import '../batches/batch_providers.dart';
import '../ponds/pond_overview.dart';
import '../reports/report_providers.dart';
import '../sales/sales_providers.dart';
import 'export_tables.dart';

/// [p]'s value. Riverpod pauses a provider no one listens to, so a plain
/// `ref.read(p.future)` from a screen that doesn't watch [p] never ends.
Future<T> _read<T>(WidgetRef ref, StreamProvider<T> p) async {
  final listening = ref.listenManual(p, (_, _) {});
  try {
    return await ref.read(p.future);
  } finally {
    listening.close();
  }
}

/// Pond, batch, origin and customer names, archived ponds included.
Future<ExportNames> loadExportNames(WidgetRef ref) async {
  final ponds = await _read(ref, allPondsByIdProvider);
  final batches = await _read(ref, batchSummariesProvider);
  final customers = await _read(ref, customersByIdProvider);
  return ExportNames(
    site: await _read(ref, siteNameProvider),
    ponds: {for (final p in ponds.values) p.id: p.code},
    batches: {for (final b in batches) b.batch.id: b.batch.code},
    origins: {
      for (final b in batches)
        b.batch.id: BatchOrigin(
          hatchery: b.batch.hatchery,
          certificateNo: b.batch.certificateNo,
        ),
    },
    customers: {for (final c in customers.values) c.id: c.name},
  );
}

/// The register's rows from [from] to [to] (farm days), for [pondIds] or
/// all ponds when null.
Future<(List<RegisterRow>, ExportNames)> loadRegister(
  WidgetRef ref, {
  required DateTime from,
  required DateTime to,
  Set<String>? pondIds,
}) async {
  final names = await loadExportNames(ref);
  final facts = await _read(ref, farmFactsProvider);
  final harvests = await ref.read(harvestRepositoryProvider).watchAll().first;
  final health = ref.read(healthRepositoryProvider);
  final treatments = await health.watchTreatmentsBetween(from, to).first;
  final events = await health.watchEventsBetween(from, to).first;
  final rows = productionRegister(
    facts: facts,
    sales: [
      for (final h in harvests)
        for (final s in h.sales)
          SaleFact(
            date: s.recordedAt,
            batchId: s.batchId,
            pondId: h.harvest.pondId,
            weightG: s.weightG,
            customerId: s.customerId,
            form: s.form,
          ),
    ],
    treatments: [
      for (final t in treatments)
        (
          t.pondId,
          TreatmentLine(
            at: t.recordedAt,
            batchId: t.batchId,
            product: t.product,
            dose: t.dose,
            advisedBy: t.advisedBy,
          ),
        ),
    ],
    health: [
      for (final e in events)
        (
          e.pondId,
          HealthLine(
            at: e.recordedAt,
            signs: e.signs,
            suspectedIssue: e.suspectedIssue,
            actions: e.actions,
          ),
        ),
    ],
    from: from,
    to: to,
    pondIds: pondIds,
    pondCodes: names.ponds,
  );
  return (rows, names);
}

/// The weekly sheet's rows over [from]–[to] widened to whole weeks, for
/// [pondIds] (every pond when null), in code order.
Future<(List<WeeklyRow>, ExportNames)> loadWeekly(
  WidgetRef ref, {
  required DateTime from,
  required DateTime to,
  Set<String>? pondIds,
}) async {
  final names = await loadExportNames(ref);
  final facts = await _read(ref, farmFactsProvider);
  final (start, end) = wholeWeeks(from, to);
  final readings = await ref
      .read(readingRepositoryProvider)
      .watchWaterReadingsBetween(start, end)
      .first;
  final ordered = (pondIds?.toList() ?? names.ponds.keys.toList())
    ..sort(
      (a, b) => (names.ponds[a] ?? a).toLowerCase().compareTo(
        (names.ponds[b] ?? b).toLowerCase(),
      ),
    );
  final rows = weeklySheet(
    facts: facts,
    readings: [
      for (final r in readings)
        (
          r.pondId,
          ReadingInfo(
            at: r.recordedAt,
            temperatureC: r.temperatureC,
            ph: r.ph,
            oxygenMgL: r.oxygenMgL,
            colour: r.colour,
          ),
        ),
    ],
    from: from,
    to: to,
    pondIds: ordered,
  );
  return (rows, names);
}
