import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/estimated.dart';
import '../common/pond_colour.dart';
import '../ponds/pond_overview.dart';
import 'batch_identity_fields.dart';
import 'batch_providers.dart';
import '../sales/sales_providers.dart';
import '../sales/sales_screen.dart';
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

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    BatchEvent event,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final repo = ref.read(batchRepositoryProvider);
    switch (event) {
      case StockingEvent(:final stocking):
        await repo.deleteStocking(stocking.id);
      case TransferEvent(:final transfer):
        await repo.deleteTransfer(transfer.id);
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(l10n.deleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ) ==
        true;
  }

  Future<void> _deleteHarvest(
    BuildContext context,
    WidgetRef ref,
    String harvestId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirmDelete(context)) return;
    try {
      await ref.read(harvestRepositoryProvider).delete(harvestId);
    } on HarvestHasSalesException {
      // This page is redrawn in step 7 Task 7; the count is not at hand.
      messenger.showSnackBar(SnackBar(content: Text(l10n.harvestHasSales(1))));
    }
  }

  Future<void> _deleteSale(
    BuildContext context,
    WidgetRef ref,
    String saleId,
  ) async {
    if (!await _confirmDelete(context)) return;
    await ref.read(harvestRepositoryProvider).deleteSale(saleId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final summary = ref
        .watch(batchSummariesProvider)
        .value
        ?.where((s) => s.batch.id == batchId)
        .firstOrNull;
    final placements = ref.watch(placementsProvider).value;
    final ponds = ref.watch(allPondsByIdProvider).value;
    final history = ref.watch(batchHistoryProvider(batchId)).value;
    final harvests = ref.watch(batchHarvestsProvider(batchId)).value;
    final customers = ref.watch(customersByIdProvider).value;
    final sales = ref.watch(sessionProvider).value?.isSales ?? false;
    if (summary == null ||
        placements == null ||
        ponds == null ||
        history == null ||
        harvests == null ||
        customers == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final b = summary.batch;
    final first = summary.firstStocking;
    final here = [
      for (final p in placements)
        if (p.batchId == batchId && (p.live.count > 0 || p.live.inconsistent))
          p,
    ];
    String pondCode(String id) => ponds[id]?.code ?? '?';
    Widget badge(String pondId) {
      final pond = ponds[pondId];
      return pond == null
          ? const SizedBox(width: 56)
          : PondTag(code: pond.code, colour: pond.colour);
    }

    final identity = [
      l10n.batchStatus(b.status),
      if (b.strain != null) b.strain!,
      if (b.hatchery != null) b.hatchery!,
      if (b.certificateNo != null) b.certificateNo!,
      if (b.monosex == true) l10n.monosex,
      if (b.plannedHarvestOn != null)
        l10n.plannedHarvestOn(formatDate(b.plannedHarvestOn!)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(b.code),
        actions: [
          IconButton(
            tooltip: l10n.traceTitle,
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => shareTrace(context, ref, batchId),
          ),
          IconButton(
            tooltip: l10n.batchEdit,
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/more/batches/$batchId/edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final line in identity) Text(line),
          if (first != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.initialStock(
                formatCount(first.count, locale),
                formatGrams(first.avgWeightMg / 1000, locale),
                formatDate(first.recordedAt),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.fishPerPond, style: theme.textTheme.titleMedium),
          for (final p in here)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  badge(p.pondId),
                  const SizedBox(width: 12),
                  EstimatedLabel(value: formatCount(p.live.count, locale)),
                  if (p.live.inconsistent) ...[
                    const SizedBox(width: 12),
                    Text(
                      l10n.inconsistent,
                      style: TextStyle(
                        color: context.dobo.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (sales) ...[
            if (here.any((p) => p.live.count > 0)) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => context.push('/more/batches/$batchId/harvest'),
                icon: const Icon(Icons.set_meal),
                label: Text(l10n.harvestAction),
              ),
            ],
            if (harvests.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => context.push('/more/batches/$batchId/sell'),
                icon: const Icon(Icons.storefront),
                label: Text(l10n.sellAction),
              ),
            ],
          ],
          if (harvests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.harvestsHeading, style: theme.textTheme.titleMedium),
            for (final h in harvests)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: HarvestLines(
                    entry: h,
                    ponds: ponds,
                    customers: customers,
                    onEdit: sales
                        ? () => context.push(
                            '/more/batches/$batchId/harvests/'
                            '${h.harvest.id}/edit',
                          )
                        : null,
                    onDelete: sales
                        ? () => _deleteHarvest(context, ref, h.harvest.id)
                        : null,
                    onDeleteSale: sales
                        ? (s) => _deleteSale(context, ref, s.id)
                        : null,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(l10n.history, style: theme.textTheme.titleMedium),
          for (final event in history)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (event) {
                      StockingEvent(:final stocking) =>
                        '${formatDate(stocking.recordedAt)} · '
                            '${l10n.eventStocking} ${pondCode(stocking.pondId)}',
                      TransferEvent(:final transfer) =>
                        '${formatDate(transfer.recordedAt)} · '
                            '${l10n.eventTransfer} ${pondCode(transfer.fromPondId)}'
                            ' → ${pondCode(transfer.toPondId)}',
                    }),
                    Text(switch (event) {
                      StockingEvent(:final stocking) =>
                        '${formatCount(stocking.count, locale)} · '
                            '${formatGrams(stocking.avgWeightMg / 1000, locale)}',
                      TransferEvent(:final transfer) => [
                        formatCount(transfer.count, locale),
                        if (transfer.avgWeightMg != null)
                          formatGrams(transfer.avgWeightMg! / 1000, locale),
                      ].join(' · '),
                    }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(88, 56),
                          ),
                          onPressed: () => context.go(switch (event) {
                            StockingEvent(:final stocking) =>
                              '/more/batches/$batchId/stockings/${stocking.id}/edit',
                            TransferEvent(:final transfer) =>
                              '/more/batches/$batchId/transfers/${transfer.id}/edit',
                          }),
                          child: Text(l10n.correct),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(88, 56),
                          ),
                          onPressed: () => _delete(context, ref, event),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  ],
                ),
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
