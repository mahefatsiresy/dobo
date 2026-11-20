import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/dates.dart';
import '../../domain/feed_lots.dart';
import '../../domain/feed_stock.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../common/attention_band.dart';
import '../common/estimated.dart';
import '../common/farm_today.dart';
import '../common/pinned_action.dart';
import 'feed_providers.dart';

/// Feed on hand, days left and each lot by phase, oldest first: the order
/// the daily logs draw from (SPEC F11, docs/design.md §Step 7).
class FeedStockScreen extends ConsumerWidget {
  const FeedStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final stock = ref.watch(feedStockProvider).value;
    final today = ref.watch(farmTodayProvider);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final lots = [
      for (final b in stock?.lots ?? const <FeedLotBalance>[])
        if (b.balanceG > 0) b,
    ];
    final expired = lots.where((b) => b.age == FeedAge.expired).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedTitle)),
      bottomNavigationBar: PinnedAction(
        icon: Icons.add,
        label: l10n.feedDeliver,
        onPressed: () => context.push('/more/feed/deliver'),
      ),
      body: stock == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.feedOnHand,
                              style: text.titleMedium,
                            ),
                          ),
                          if (stock.daysLeft != null)
                            EstimatedLabel(
                              value: l10n.feedDaysLeftShort(
                                formatDecimal(
                                  stock.daysLeft!,
                                  locale,
                                  decimals: 0,
                                ),
                              ),
                              style: text.titleMedium,
                            ),
                        ],
                      ),
                      Text(
                        formatKg(stock.onHandG, locale),
                        key: const ValueKey('feed-total'),
                        style: text.headlineSmall,
                      ),
                      if (stock.daysLeft == null)
                        Text(l10n.feedNoUsage, style: text.bodySmall),
                    ],
                  ),
                ),
                if (expired != null)
                  AttentionBand(
                    severity: BandSeverity.danger,
                    text: l10n.feedExpiredBand(
                      formatKg(stock.expiredG, locale),
                    ),
                    onTap: () =>
                        context.push('/more/feed/${expired.lot.id}/discard'),
                  ),
                if (stock.overdrawnG > 0)
                  AttentionBand(
                    severity: BandSeverity.warning,
                    text: l10n.feedOverdrawn(
                      formatKg(stock.overdrawnG, locale),
                    ),
                  ),
                Divider(height: 1, thickness: 1, color: c.line),
                if (lots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.feedNoLots),
                  ),
                for (final phase in Phase.values)
                  if (lots.any((b) => b.lot.phase == phase)) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.phase(phase),
                              style: text.titleMedium,
                            ),
                          ),
                          Text(
                            formatKg(
                              lots
                                  .where(
                                    (b) =>
                                        b.lot.phase == phase &&
                                        b.age != FeedAge.expired,
                                  )
                                  .fold(0, (n, b) => n + b.balanceG),
                              locale,
                            ),
                            style: text.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    for (final b in lots)
                      if (b.lot.phase == phase) _LotRow(lot: b, today: today),
                  ],
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

class _LotRow extends StatelessWidget {
  const _LotRow({required this.lot, required this.today});

  final FeedLotBalance lot;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final l = lot.lot;
    final age = switch (lot.age) {
      FeedAge.ok => null,
      FeedAge.old => (Icons.warning_amber, c.warning, l10n.feedLotOld),
      FeedAge.expired => (Icons.error, c.danger, l10n.feedLotExpired),
    };
    return InkWell(
      key: ValueKey('lot-${l.id}'),
      onTap: () => context.push('/more/feed/${l.id}'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.feedLotLine(
                        l.label ?? l10n.feedLotUnnamed,
                        formatDate(l.manufacturedOn),
                        '${daysBetween(l.manufacturedOn, today)}',
                      ),
                    ),
                    if (age case (final icon, final colour, final words))
                      Row(
                        children: [
                          Icon(icon, color: colour, size: 20),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              words,
                              style: text.bodySmall?.copyWith(
                                color: colour,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(formatKg(lot.balanceG, locale), style: text.titleMedium),
              Icon(Icons.chevron_right, color: c.ink),
            ],
          ),
        ),
      ),
    );
  }
}
