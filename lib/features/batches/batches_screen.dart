import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/estimated.dart';
import '../ponds/pond_overview.dart';

class BatchesScreen extends ConsumerWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final summaries = ref.watch(batchSummariesProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreBatches)),
      body: summaries == null
          ? const Center(child: CircularProgressIndicator())
          : summaries.isEmpty
          ? Center(child: Text(l10n.batchesEmpty))
          : ListView(
              children: [
                for (final s in summaries)
                  ListTile(
                    minTileHeight: 56,
                    leading: const Icon(Icons.set_meal),
                    title: Text(s.batch.code),
                    subtitle: Text(
                      [
                        l10n.batchStatus(s.batch.status),
                        if (s.firstStocking != null)
                          l10n.stockedOn(
                            formatDate(s.firstStocking!.recordedAt),
                          ),
                      ].join(' · '),
                    ),
                    trailing: EstimatedLabel(
                      value: formatCount(s.liveCount, locale),
                    ),
                    onTap: () => context.go('/more/batches/${s.batch.id}'),
                  ),
              ],
            ),
    );
  }
}
