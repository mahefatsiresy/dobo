import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/batch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../batches/batch_providers.dart';
import '../ponds/pond_overview.dart';
import 'harvest_rows.dart';
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batches[h.harvest.batchId] ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            HarvestRows(
                              entry: h,
                              ponds: ponds,
                              customers: customers,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
