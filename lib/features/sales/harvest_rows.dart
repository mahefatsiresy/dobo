import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/harvest_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/sales.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../common/pond_colour.dart';

/// A harvest and its sales as rows, on the batch page and on Ventes
/// (docs/design.md §Step 7). With the sales flag each row opens its
/// correction, and kilos left to sell come with a Vendre button.
class HarvestRows extends ConsumerWidget {
  const HarvestRows({
    super.key,
    required this.entry,
    required this.ponds,
    required this.customers,
  });

  final HarvestWithSales entry;
  final Map<String, Pond> ponds;
  final Map<String, Customer> customers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final sales = ref.watch(sessionProvider).value?.isSales ?? false;
    final h = entry.harvest;
    final batch = h.batchId;
    final pond = ponds[h.pondId];
    final unsold = unsoldG(h.weightG, [for (final s in entry.sales) s.weightG]);

    Widget tappable({
      required Key key,
      required Widget child,
      required String route,
      double indent = 0,
    }) => InkWell(
      key: key,
      onTap: sales ? () => context.push(route) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: EdgeInsets.only(left: indent),
          child: Row(
            children: [
              Expanded(child: child),
              if (sales) Icon(Icons.chevron_right, color: c.ink),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tappable(
          key: ValueKey('harvest-${h.id}'),
          route: '/more/batches/$batch/harvests/${h.id}/edit',
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(formatDate(h.recordedAt)),
              PondCode(code: pond?.code ?? '?', colour: pond?.colour),
              Text(
                l10n.harvestRowLine(
                  h.isFinal ? l10n.harvestFinalShort : l10n.harvestPartial,
                  formatCount(h.count, locale),
                  formatKg(h.weightG, locale),
                ),
              ),
            ],
          ),
        ),
        for (final s in entry.sales)
          tappable(
            key: ValueKey('sale-${s.id}'),
            route: '/more/batches/$batch/sales/${s.id}/edit',
            indent: 24,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.saleRowLine(
                      customers[s.customerId]?.name ?? '?',
                      l10n.productForm(s.form),
                    ),
                  ),
                ),
                Text(formatKg(s.weightG, locale), style: text.titleSmall),
              ],
            ),
          ),
        if (unsold > 0)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(l10n.unsoldLine(formatKg(unsold, locale))),
                if (sales)
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/more/batches/$batch/sell?harvestId=${h.id}',
                    ),
                    icon: const Icon(Icons.storefront),
                    label: Text(l10n.sellAction),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
