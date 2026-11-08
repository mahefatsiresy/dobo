import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/trace.dart';
import '../../l10n/app_localizations.dart';
import '../batches/batch_providers.dart';
import '../common/farm_today.dart';
import '../ponds/pond_overview.dart';
import '../reports/share_report.dart';
import 'sales_providers.dart';
import 'trace_pdf.dart';

/// [batchId]'s traceability sheet from this phone's records.
Future<BatchTraceView> loadTraceView(WidgetRef ref, String batchId) async {
  final facts = await ref.read(farmFactsProvider.future);
  final summary = (await ref.read(batchSummariesProvider.future))
      .firstWhere((s) => s.batch.id == batchId);
  final ponds = await ref.read(allPondsByIdProvider.future);
  final history = await ref.read(batchHistoryProvider(batchId).future);
  final harvests = await ref.read(batchHarvestsProvider(batchId).future);
  final customers = await ref.read(customersByIdProvider.future);
  final treatments = await ref
      .read(healthRepositoryProvider)
      .watchTreatmentsBetween(DateTime(2000), DateTime(2100))
      .first;
  String code(String id) => ponds[id]?.code ?? '?';
  final b = summary.batch;
  final first = summary.firstStocking;
  return BatchTraceView(
    code: b.code,
    strain: b.strain,
    hatchery: b.hatchery,
    certificateNo: b.certificateNo,
    monosex: b.monosex,
    stockedOn: first?.recordedAt,
    stockedAvgWeightG: first == null ? null : first.avgWeightMg / 1000,
    trace: batchTrace(facts, batchId, status: b.status),
    moves: [
      for (final e in history.reversed)
        switch (e) {
          StockingEvent(:final stocking) => TraceMove(
            at: stocking.recordedAt,
            toPond: code(stocking.pondId),
            count: stocking.count,
            avgWeightG: stocking.avgWeightMg / 1000,
          ),
          TransferEvent(:final transfer) => TraceMove(
            at: transfer.recordedAt,
            fromPond: code(transfer.fromPondId),
            toPond: code(transfer.toPondId),
            count: transfer.count,
            avgWeightG: transfer.avgWeightMg == null
                ? null
                : transfer.avgWeightMg! / 1000,
          ),
        },
    ],
    treatments: [
      for (final t in treatments)
        if (treatmentConcernsBatch(
          facts,
          batchId,
          treatmentBatchId: t.batchId,
          pondId: t.pondId,
          date: t.recordedAt,
        ))
          TraceTreatment(
            at: t.recordedAt,
            pond: code(t.pondId),
            product: t.product,
            dose: t.dose,
            advisedBy: t.advisedBy,
          ),
    ],
    harvests: [
      for (final h in harvests.reversed)
        TraceHarvest(
          at: h.harvest.recordedAt,
          pond: code(h.harvest.pondId),
          count: h.harvest.count,
          weightG: h.harvest.weightG,
          isFinal: h.harvest.isFinal,
          sales: [
            for (final s in h.sales)
              TraceSale(
                at: s.recordedAt,
                customer: customers[s.customerId]?.name ?? '?',
                form: s.form,
                weightG: s.weightG,
              ),
          ],
        ),
    ],
  );
}

/// Builds [batchId]'s sheet in the phone's language and shares it through
/// any app, with no server (SPEC F12).
Future<void> shareTrace(
  BuildContext context,
  WidgetRef ref,
  String batchId,
) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context);
  final today = ref.read(farmTodayProvider);
  final view = await loadTraceView(ref, batchId);
  final fonts = await pdfFonts();
  final bytes = await buildTracePdf(
    view,
    l10n,
    locale,
    regular: fonts.regular,
    bold: fonts.bold,
    symbols: fonts.symbols,
  );
  await sharePdfFile(ref, traceFileName(view.code, today), bytes);
}
