import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/providers.dart';
import '../../domain/farm_facts.dart';
import '../../domain/fcr.dart';
import '../../domain/growth.dart';
import '../../domain/trace.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/estimated.dart';
import '../common/pond_colour.dart';
import '../ponds/pond_overview.dart';
import 'batch_identity_fields.dart';
import 'batch_providers.dart';
import '../sales/sales_providers.dart';
import '../sales/harvest_rows.dart';
import '../common/coded_band.dart';
import '../common/folded_section.dart';
import 'batch_rows.dart';
import 'batches_screen.dart';
import '../sales/share_trace.dart';
import '../common/save_once.dart';
import '../common/form_body.dart';
import '../common/details_fold.dart';
import '../common/form_menu.dart';
import '../common/pinned_action.dart';
import '../../theme/tokens.dart';

class BatchDetailScreen extends ConsumerWidget {
  const BatchDetailScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final summary = ref
        .watch(batchSummariesProvider)
        .value
        ?.where((s) => s.batch.id == batchId)
        .firstOrNull;
    final rows = ref.watch(batchRowsProvider).value;
    final ponds = ref.watch(allPondsByIdProvider).value;
    final history = ref.watch(batchHistoryProvider(batchId)).value;
    final harvests = ref.watch(batchHarvestsProvider(batchId)).value;
    final customers = ref.watch(customersByIdProvider).value;
    final facts = ref.watch(farmFactsProvider).value;
    final sales = ref.watch(sessionProvider).value?.isSales ?? false;
    if (summary == null ||
        rows == null ||
        ponds == null ||
        history == null ||
        harvests == null ||
        customers == null ||
        facts == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final b = summary.batch;
    final closed = b.status == BatchStatus.closed;
    final row = rows.where((r) => r.batch.id == batchId).firstOrNull;
    final places = row?.places ?? const <BatchPlace>[];
    final live = places.any((p) => p.placement.live.count > 0);
    String code(String id) => ponds[id]?.code ?? '?';
    Widget rule() => Divider(height: 1, thickness: 1, color: c.line);
    Widget heading(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: text.titleMedium),
    );
    final survival = batchSurvival(facts, batchId);
    String pct(double v) => formatDecimal(v * 100, locale, decimals: 0);

    final pinned = closed
        ? PinnedAction(
            icon: Icons.picture_as_pdf,
            label: l10n.traceTitle,
            onPressed: () => shareTrace(context, ref, batchId),
          )
        : sales && live
        ? PinnedAction(
            icon: Icons.set_meal,
            label: l10n.harvestAction,
            onPressed: () => context.push('/more/batches/$batchId/harvest'),
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.code),
            Text(
              row?.phase == null
                  ? l10n.batchStatus(b.status)
                  : l10n.phase(row!.phase!),
              style: text.bodySmall,
            ),
          ],
        ),
        actions: [
          FormMenu(
            entries: [
              FormMenuEntry(
                label: l10n.batchEdit,
                icon: Icons.edit,
                onTap: () => context.go('/more/batches/$batchId/edit'),
              ),
              FormMenuEntry(
                label: l10n.traceTitle,
                icon: Icons.picture_as_pdf,
                onTap: () => shareTrace(context, ref, batchId),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: pinned,
      body: ListView(
        children: [
          for (final item in row?.items ?? const <BatchItem>[])
            CodedBand(
              severity: item.severity,
              text: batchItemText(l10n, item, b.code),
              code: item.pond?.code,
              colour: item.pond?.colour,
              onTap: () => context.go(batchItemRoute(item)),
            ),
          if (closed)
            _ClosedOutcome(batchId: batchId, summary: summary, facts: facts)
          else ...[
            for (final p in places)
              InkWell(
                key: ValueKey('place-${p.pond.id}'),
                onTap: () => context.go('/ponds/${p.pond.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: PondCode(
                            code: p.pond.code,
                            colour: p.pond.colour,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EstimatedLabel(
                              value: l10n.pondFishCount(
                                formatCount(p.placement.live.count, locale),
                              ),
                              style: text.titleMedium,
                            ),
                            Text(
                              [
                                if (p.placement.avgWeightG != null)
                                  formatGrams(p.placement.avgWeightG!, locale),
                                if (p.biomassG != null)
                                  approx(formatKg(p.biomassG!, locale)),
                              ].join(', '),
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: c.ink),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (places.length > 1 && row != null)
                    EstimatedLabel(
                      value: l10n.pondFishCount(
                        formatCount(row.liveCount, locale),
                      ),
                      trailing: row.biomassG == null
                          ? ''
                          : ', ${approx(formatKg(row.biomassG!, locale))}',
                    ),
                  if (survival != null) Text(l10n.survivalValue(pct(survival))),
                ],
              ),
            ),
          ],
          rule(),
          if (harvests.isNotEmpty) ...[
            heading(l10n.harvestsHeading),
            for (final h in harvests)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HarvestRows(
                  entry: h,
                  ponds: ponds,
                  customers: customers,
                ),
              ),
            rule(),
          ],
          heading(l10n.history),
          for (final event in history)
            InkWell(
              key: ValueKey(
                'event-${switch (event) {
                  StockingEvent(:final stocking) => stocking.id,
                  TransferEvent(:final transfer) => transfer.id,
                }}',
              ),
              onTap: () => context.push(switch (event) {
                StockingEvent(:final stocking) =>
                  '/more/batches/$batchId/stockings/${stocking.id}/edit',
                TransferEvent(:final transfer) =>
                  '/more/batches/$batchId/transfers/${transfer.id}/edit',
              }),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(switch (event) {
                        StockingEvent() => Icons.add,
                        TransferEvent() => Icons.swap_horiz,
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: switch (event) {
                            StockingEvent(:final stocking) => [
                              Text(formatDate(stocking.recordedAt)),
                              Text(
                                code(stocking.pondId),
                                style: text.titleSmall,
                              ),
                              Text(
                                l10n.historyFishWeight(
                                  formatCount(stocking.count, locale),
                                  formatGrams(
                                    stocking.avgWeightMg / 1000,
                                    locale,
                                  ),
                                ),
                              ),
                            ],
                            TransferEvent(:final transfer) => [
                              Text(formatDate(transfer.recordedAt)),
                              // An icon: the bundled faces have no "→".
                              Row(
                                key: const ValueKey('transfer-ponds'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    code(transfer.fromPondId),
                                    style: text.titleSmall,
                                  ),
                                  const Icon(Icons.arrow_forward, size: 18),
                                  Text(
                                    code(transfer.toPondId),
                                    style: text.titleSmall,
                                  ),
                                ],
                              ),
                              Text(
                                l10n.historyFish(
                                  formatCount(transfer.count, locale),
                                ),
                              ),
                            ],
                          },
                        ),
                      ),
                      Icon(Icons.chevron_right, color: c.ink),
                    ],
                  ),
                ),
              ),
            ),
          rule(),
          FoldedSection(
            title: l10n.batchOrigin,
            summary: [?b.hatchery, ?b.certificateNo].join(', ').isEmpty
                ? l10n.notSpecified
                : [?b.hatchery, ?b.certificateNo].join(', '),
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.strain != null)
                  Text(l10n.labelValue(l10n.strain, b.strain!)),
                if (b.hatchery != null)
                  Text(l10n.labelValue(l10n.hatchery, b.hatchery!)),
                if (b.certificateNo != null)
                  Text(l10n.labelValue(l10n.certificate, b.certificateNo!)),
                if (b.monosex == true) Text(l10n.monosex),
                if (b.plannedHarvestOn != null)
                  Text(l10n.plannedHarvestOn(formatDate(b.plannedHarvestOn!))),
                if (summary.firstStocking case final first?)
                  Text(
                    l10n.initialStock(
                      formatCount(first.count, locale),
                      formatGrams(first.avgWeightMg / 1000, locale),
                      formatDate(first.recordedAt),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// A closed batch's cycle: what was harvested, its FCR and survival, and
/// how it started (the traceability sheet's figures).
class _ClosedOutcome extends StatelessWidget {
  const _ClosedOutcome({
    required this.batchId,
    required this.summary,
    required this.facts,
  });

  final String batchId;
  final BatchSummary summary;
  final FarmFacts facts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final t = batchTrace(facts, batchId, status: BatchStatus.closed);
    final first = summary.firstStocking;
    // No feed logged for the batch: a ratio of 0 would look measured.
    final fcr = switch (t.cycleFcr) {
      _ when t.batchFeedG == 0 => null,
      FcrValue(:final value) => formatDecimal(value, locale),
      FcrStalled() => l10n.fcrStalled,
      null => null,
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.batchHarvestedLine(
              formatCount(t.harvestedCount, locale),
              formatKg(t.harvestedWeightG, locale),
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (fcr != null) Text(l10n.batchCycleFcr(fcr)),
          if (t.survival != null)
            Text(
              l10n.survivalValue(
                formatDecimal(t.survival! * 100, locale, decimals: 0),
              ),
            ),
          if (first != null)
            Text(
              l10n.initialStock(
                formatCount(first.count, locale),
                formatGrams(first.avgWeightMg / 1000, locale),
                formatDate(first.recordedAt),
              ),
            ),
        ],
      ),
    );
  }
}

/// Edits a batch's identity fields.
class BatchFormScreen extends ConsumerStatefulWidget {
  const BatchFormScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<BatchFormScreen> createState() => _BatchFormScreenState();
}

class _BatchFormScreenState extends ConsumerState<BatchFormScreen>
    with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _identity = BatchIdentity();
  Batch? _batch;

  @override
  void dispose() {
    _identity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _identity.codeError = null);
    if (!_form.currentState!.validate()) return;
    try {
      await ref
          .read(batchRepositoryProvider)
          .updateBatch(widget.batchId, _identity.input());
      if (!mounted) return;
      showDone(context, AppLocalizations.of(context).doneSaved);
      context.go('/more/batches/${widget.batchId}');
    } on DuplicateCodeException {
      if (mounted) {
        setState(
          () =>
              _identity.codeError = AppLocalizations.of(context).duplicateCode,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A new batch id (the same page shown for another batch) loads anew.
    if (_batch?.id != widget.batchId) {
      final b = ref
          .watch(batchSummariesProvider)
          .value
          ?.where((s) => s.batch.id == widget.batchId)
          .firstOrNull
          ?.batch;
      if (b == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _batch = b;
      _identity.load(b);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.batchEdit)),
      bottomNavigationBar: PinnedAction(
        icon: Icons.check,
        label: l10n.actionSaveBatch,
        onPressed: saving ? null : () => saveOnce(_save),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            batchCodeField(context, _identity),
            const SizedBox(height: 16),
            plannedHarvestField(
              context,
              _identity,
              onChanged: () => setState(() {}),
            ),
            DetailsFold(
              key: ValueKey(widget.batchId),
              initiallyOpen: _identity.hasDetails,
              children: batchDetailFields(
                context,
                _identity,
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
