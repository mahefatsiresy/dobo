import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../alerts/alert_route.dart';
import '../common/coded_band.dart';
import '../common/estimated.dart';
import '../common/folded_section.dart';
import '../common/pond_colour.dart';
import '../ponds/pond_attention.dart';
import '../ponds/pond_row.dart';
import 'batch_rows.dart';

/// Where a band's item is fixed: its alert's screen, or the pond's page.
String batchItemRoute(BatchItem item) => switch (item.lead) {
  LeadAlert(:final alert) => alertRoute(alert) ?? '/ponds/${item.pond?.id}',
  _ => '/ponds/${item.pond?.id}',
};

/// What a batch's item says; an alert names the batch.
String batchItemText(AppLocalizations l10n, BatchItem item, String batchCode) =>
    switch (item.lead) {
      LeadAlert(:final alert) => l10n.alertText(alert, batchCode: batchCode),
      final lead => leadText(l10n, lead, null),
    };

/// The batches still in the ponds, for a glance (docs/design.md §Step 7).
class BatchesScreen extends ConsumerWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rows = ref.watch(batchRowsProvider).value;
    final closed = ref.watch(closedBatchesProvider).value ?? const [];
    final c = context.dobo;
    Widget rule() => Divider(height: 1, thickness: 1, color: c.line);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreBatches)),
      body: rows == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (rows.isEmpty && closed.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.batchesEmpty),
                  ),
                for (final r in rows) ...[_BatchListRow(row: r), rule()],
                if (closed.isNotEmpty) ...[
                  FoldedSection(
                    title: l10n.batchesClosed,
                    summary: l10n.batchesClosedCount(closed.length),
                    builder: (context) => Column(
                      children: [
                        for (final b in closed)
                          ListTile(
                            minTileHeight: 56,
                            contentPadding: EdgeInsets.zero,
                            title: Text(b.batch.code),
                            subtitle: b.closedOn == null
                                ? null
                                : Text(
                                    l10n.batchClosedOn(formatDate(b.closedOn!)),
                                  ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                context.go('/more/batches/${b.batch.id}'),
                          ),
                      ],
                    ),
                  ),
                  rule(),
                ],
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.add),
                  title: Text(l10n.batchesStockRow),
                  onTap: () => context.push('/stock'),
                ),
              ],
            ),
    );
  }
}

class _BatchListRow extends StatelessWidget {
  const _BatchListRow({required this.row});

  final BatchRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final r = row;
    final a = r.attention;
    final lead = r.items.firstOrNull;
    final figures = [
      if (r.avgWeightG != null) formatGrams(r.avgWeightG!, locale),
      if (r.biomassG != null) approx(formatKg(r.biomassG!, locale)),
    ].join(', ');
    return InkWell(
      key: ValueKey('batch-row-${r.batch.code}'),
      onTap: () => context.go('/more/batches/${r.batch.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (a != null && lead != null) ...[
              CodedBand(
                severity: a.severity,
                text: a.more == 0
                    ? batchItemText(l10n, lead, r.batch.code)
                    : l10n.bandMore(
                        batchItemText(l10n, lead, r.batch.code),
                        a.more,
                      ),
                code: lead.pond?.code,
                colour: lead.pond?.colour,
                onTap: () => context.go(batchItemRoute(lead)),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.batch.code,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        r.phase == null
                            ? l10n.batchStatus(r.batch.status)
                            : l10n.phase(r.phase!),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final p in r.places)
                            PondCode(code: p.pond.code, colour: p.pond.colour),
                          if (figures.isNotEmpty)
                            Text(figures, style: text.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    EstimatedLabel(
                      value: formatCount(r.liveCount, locale),
                      style: text.titleMedium,
                    ),
                    Text(l10n.fishUnit, style: text.bodySmall),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
