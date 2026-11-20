import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/alerts/alert.dart';
import '../../domain/dates.dart';
import '../../domain/occupancy.dart';
import '../../domain/phase.dart';
import '../../domain/stock.dart';
import '../../domain/types.dart';
import '../alerts/alert_providers.dart';
import '../common/attention_band.dart';
import '../ponds/pond_attention.dart';
import '../ponds/pond_overview.dart';
import '../sales/sales_providers.dart';
import 'batch_providers.dart';

/// One pond a batch is in, with what it holds there.
class BatchPlace {
  const BatchPlace({
    required this.pond,
    required this.placement,
    required this.biomassG,
  });

  final Pond pond;
  final Placement placement;

  /// Null while no weight is known.
  final int? biomassG;
}

/// Something about a batch that needs a person, and the pond it's in.
class BatchItem {
  const BatchItem(this.lead, this.severity, this.pond);

  final AttentionLead lead;
  final BandSeverity severity;
  final Pond? pond;
}

/// A batch still in the ponds, for the batches list and its page
/// (docs/design.md §Step 7).
class BatchRow {
  const BatchRow({
    required this.batch,
    required this.places,
    required this.items,
    required this.phase,
  });

  final Batch batch;

  /// The phase while active in one pond with a known weight.
  final Phase? phase;

  /// The ponds holding it (fish, or a count that doesn't add up), by code.
  final List<BatchPlace> places;

  /// Isolated ponds, then counts to check, then the batch's alerts in
  /// alert order.
  final List<BatchItem> items;

  int get liveCount => places.fold(0, (n, p) => n + p.placement.live.count);

  /// Only for a batch in one pond, as on the ponds list.
  double? get avgWeightG =>
      places.length == 1 ? places.single.placement.avgWeightG : null;

  /// Null when a place has no known weight.
  int? get biomassG => places.any((p) => p.biomassG == null)
      ? null
      : places.fold<int>(0, (n, p) => n + p.biomassG!);

  /// The band of the list: the first item and how many more.
  PondAttention? get attention => items.isEmpty
      ? null
      : PondAttention(
          severity: items.first.severity,
          lead: items.first.lead,
          more: items.length - 1,
        );
}

List<BatchRow> buildBatchRows({
  required List<Batch> batches,
  required List<Placement> placements,
  required Map<String, Pond> ponds,
  required List<Alert> alerts,
  required Phase Function(double avgWeightG) phaseOf,
}) {
  final rows = <BatchRow>[];
  for (final b in [...batches]..sort((a, b) => a.code.compareTo(b.code))) {
    if (b.status == BatchStatus.closed) continue;
    final places = [
      for (final p in placements)
        if (p.batchId == b.id &&
            (p.live.count > 0 || p.live.inconsistent) &&
            ponds[p.pondId] != null)
          BatchPlace(
            pond: ponds[p.pondId]!,
            placement: p,
            biomassG: p.avgWeightG == null
                ? null
                : biomassG(liveCount: p.live.count, avgWeightG: p.avgWeightG!),
          ),
    ]..sort((x, y) => x.pond.code.compareTo(y.pond.code));
    final items = [
      for (final p in places)
        if (p.pond.status == PondStatus.isolated)
          BatchItem(const LeadIsolated(), BandSeverity.danger, p.pond),
      for (final p in places)
        if (p.placement.live.inconsistent)
          BatchItem(const LeadInconsistent(), BandSeverity.danger, p.pond),
      for (final a in alerts)
        if (a.batchId == b.id)
          BatchItem(
            LeadAlert(a),
            a.severity == Severity.danger
                ? BandSeverity.danger
                : BandSeverity.warning,
            ponds[a.pondId],
          ),
    ];
    final weight = places.length == 1
        ? places.single.placement.avgWeightG
        : null;
    rows.add(
      BatchRow(
        batch: b,
        places: places,
        items: items,
        phase: b.status == BatchStatus.active && weight != null
            ? phaseOf(weight)
            : null,
      ),
    );
  }
  return rows;
}

/// Open batches in code order (docs/design.md §Step 7).
final batchRowsProvider = Provider<AsyncValue<List<BatchRow>>>((ref) {
  final summaries = ref.watch(batchSummariesProvider);
  final placements = ref.watch(placementsProvider);
  final ponds = ref.watch(allPondsByIdProvider);
  final alerts = ref.watch(alertsProvider);
  final config = ref.watch(domainConfigProvider);
  for (final v in [summaries, placements, ponds, alerts]) {
    if (v is AsyncError) return AsyncError(v.error!, v.stackTrace!);
  }
  if (!summaries.hasValue ||
      !placements.hasValue ||
      !ponds.hasValue ||
      !alerts.hasValue) {
    return const AsyncLoading();
  }
  return AsyncData(
    buildBatchRows(
      batches: [for (final s in summaries.requireValue) s.batch],
      placements: placements.requireValue,
      ponds: ponds.requireValue,
      alerts: alerts.requireValue,
      phaseOf: (g) => phaseFor(g, config),
    ),
  );
});

/// A closed batch and the day of its last harvest.
class ClosedBatch {
  const ClosedBatch(this.batch, this.closedOn);

  final Batch batch;
  final DateTime? closedOn;
}

/// Closed batches, the latest closed first.
final closedBatchesProvider = Provider<AsyncValue<List<ClosedBatch>>>((ref) {
  final summaries = ref.watch(batchSummariesProvider);
  final harvests = ref.watch(allHarvestsProvider);
  if (!summaries.hasValue || !harvests.hasValue) return const AsyncLoading();
  final last = <String, DateTime>{};
  for (final h in harvests.requireValue) {
    final d = farmDate(h.harvest.recordedAt);
    final seen = last[h.harvest.batchId];
    if (seen == null || d.isAfter(seen)) last[h.harvest.batchId] = d;
  }
  final closed = [
    for (final s in summaries.requireValue)
      if (s.batch.status == BatchStatus.closed)
        ClosedBatch(s.batch, last[s.batch.id]),
  ];
  return AsyncData(
    closed..sort(
      (a, b) =>
          (b.closedOn ?? DateTime(0)).compareTo(a.closedOn ?? DateTime(0)),
    ),
  );
});
