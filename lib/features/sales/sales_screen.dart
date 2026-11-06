import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/harvest_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../batches/batch_providers.dart';
import '../ponds/pond_overview.dart';
import 'sales_providers.dart';

/// Every harvest with its sales, newest first (SPEC F12).
class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final harvests = ref.watch(allHarvestsProvider).value;
    final ponds = ref.watch(allPondsByIdProvider).value;
    final customers = ref.watch(customersByIdProvider).value;
    final batches = <String, String>{
      for (final s
          in ref.watch(batchSummariesProvider).value ?? const <BatchSummary>[])
        s.batch.id: s.batch.code,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.salesTitle)),
      body: harvests == null || ponds == null || customers == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () => context.go('/more/sales/customers'),
                  icon: const Icon(Icons.people),
                  label: Text(l10n.customersTitle),
                ),
                const SizedBox(height: 16),
                if (harvests.isEmpty) Text(l10n.salesNone),
                for (final h in harvests)
                  Card(
                    child: InkWell(
                      onTap: () =>
                          context.go('/more/batches/${h.harvest.batchId}'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: HarvestLines(
                          entry: h,
                          title: batches[h.harvest.batchId],
                          ponds: ponds,
                          customers: customers,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// A harvest's line and its sales under it.
class HarvestLines extends StatelessWidget {
  const HarvestLines({
    super.key,
    required this.entry,
    required this.ponds,
    required this.customers,
    this.title,
  });

  final HarvestWithSales entry;
  final Map<String, Pond> ponds;
  final Map<String, Customer> customers;

  /// The batch code, when the list mixes batches.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final h = entry.harvest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(title!, style: Theme.of(context).textTheme.titleMedium),
        Text(
          l10n.harvestLine(
            formatDate(h.recordedAt),
            h.isFinal ? l10n.harvestKindFinal : l10n.harvestKindPartial,
            ponds[h.pondId]?.code ?? '?',
            formatCount(h.count, locale),
            formatKg(h.weightG, locale),
          ),
        ),
        for (final s in entry.sales)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              l10n.saleLine(
                customers[s.customerId]?.name ?? '?',
                l10n.productForm(s.form),
                formatKg(s.weightG, locale),
              ),
            ),
          ),
      ],
    );
  }
}
