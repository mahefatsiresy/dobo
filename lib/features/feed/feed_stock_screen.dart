import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../domain/feed_lots.dart';
import '../../domain/feed_stock.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/farm_today.dart';
import '../common/notice.dart';
import 'feed_providers.dart';
import '../../theme/tokens.dart';

/// Feed on hand, days left and each lot's age (SPEC F11).
class FeedStockScreen extends ConsumerWidget {
  const FeedStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final stock = ref.watch(feedStockProvider).value;
    final today = ref.watch(farmTodayProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'feed-deliver',
        onPressed: () => context.push('/more/feed/deliver'),
        icon: const Icon(Icons.add),
        label: Text(l10n.feedDeliver),
      ),
      body: stock == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(l10n.feedOnHand, style: theme.textTheme.titleMedium),
                Text(
                  formatKg(stock.onHandG, locale),
                  style: theme.textTheme.displaySmall,
                ),
                Text(
                  stock.daysLeft == null
                      ? l10n.feedNoUsage
                      : l10n.feedDaysLeft(
                          formatDecimal(stock.daysLeft!, locale, decimals: 0),
                        ),
                ),
                if (stock.expiredG > 0)
                  Notice(
                    l10n.feedExpiredStock(formatKg(stock.expiredG, locale)),
                    danger: true,
                  ),
                if (stock.overdrawnG > 0)
                  Notice(
                    l10n.feedOverdrawn(formatKg(stock.overdrawnG, locale)),
                  ),
                const SizedBox(height: 16),
                if (stock.lots.isEmpty) Text(l10n.feedNoLots),
                for (final b in stock.lots)
                  if (b.balanceG > 0) _LotCard(lot: b, today: today),
              ],
            ),
    );
  }
}

class _LotCard extends ConsumerWidget {
  const _LotCard({required this.lot, required this.today});

  final FeedLotBalance lot;
  final DateTime today;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
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
    if (ok == true) {
      await ref.read(feedRepositoryProvider).deleteDelivery(lot.lot.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final l = lot.lot;
    final badge = switch (lot.age) {
      FeedAge.ok => null,
      FeedAge.old => (l10n.feedLotOld, context.dobo.warning),
      FeedAge.expired => (l10n.feedLotExpired, context.dobo.danger),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (l.label != null) l.label!,
                      l10n.phase(l.phase),
                    ].join(' · '),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    l10n.feedLotMade(
                      formatDate(l.manufacturedOn),
                      '${daysBetween(l.manufacturedOn, today)}',
                    ),
                  ),
                  if (badge != null)
                    Text(
                      badge.$1,
                      style: TextStyle(
                        color: badge.$2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatKg(lot.balanceG, locale),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  key: ValueKey('lot-delete-${l.id}'),
                  style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
                  onPressed: () => _delete(context, ref),
                  child: Text(l10n.feedDeleteDelivery),
                ),
                TextButton.icon(
                  key: ValueKey('discard-${l.id}'),
                  style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
                  onPressed: () => context.push('/more/feed/${l.id}/discard'),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.feedDiscard),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
