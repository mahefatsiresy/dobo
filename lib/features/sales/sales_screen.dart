import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/batch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../batches/batch_providers.dart';
import '../ponds/pond_overview.dart';
import '../../db/repositories/harvest_repository.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import 'harvest_rows.dart';
import 'sales_providers.dart';

/// Harvests and their sales by batch, the latest activity first, with
/// what is left to sell (SPEC F12, docs/design.md §Step 7).
class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final harvests = ref.watch(allHarvestsProvider).value;
    final ponds = ref.watch(allPondsByIdProvider).value;
    final customers = ref.watch(customersByIdProvider).value;
    final active = ref.watch(activeCustomersProvider).value;
    final batches = {
      for (final s
          in ref.watch(batchSummariesProvider).value ?? const <BatchSummary>[])
        s.batch.id: s.batch,
    };
    if (harvests == null || ponds == null || customers == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Each batch's harvests, newest first; batches by their newest harvest.
    final byBatch = <String, List<HarvestWithSales>>{};
    for (final h in harvests) {
      (byBatch[h.harvest.batchId] ??= []).add(h);
    }
    for (final list in byBatch.values) {
      list.sort((a, b) => b.harvest.recordedAt.compareTo(a.harvest.recordedAt));
    }
    final order = byBatch.keys.toList()
      ..sort(
        (a, b) => byBatch[b]!.first.harvest.recordedAt.compareTo(
          byBatch[a]!.first.harvest.recordedAt,
        ),
      );
    Widget rule() => Divider(height: 1, thickness: 1, color: c.line);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.salesTitle)),
      body: ListView(
        children: [
          ListTile(
            key: const ValueKey('sales-clients'),
            minTileHeight: 56,
            leading: const Icon(Icons.people),
            title: Text(l10n.customersTitle),
            subtitle: active == null
                ? null
                : Text(l10n.customersCount(active.length)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/sales/customers'),
          ),
          rule(),
          if (harvests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.salesNone),
            ),
          for (final id in order) ...[
            ListTile(
              key: ValueKey('sales-batch-${batches[id]?.code}'),
              minTileHeight: 56,
              title: Text(batches[id]?.code ?? '?', style: text.titleMedium),
              subtitle: batches[id] == null
                  ? null
                  : Text(l10n.batchStatus(batches[id]!.status)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/more/batches/$id'),
            ),
            for (final h in byBatch[id]!)
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
        ],
      ),
    );
  }
}
