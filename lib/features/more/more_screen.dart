import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../locale_controller.dart';
import '../../domain/types.dart';
import '../../l10n/formatting.dart';
import '../../sync/providers.dart';
import '../../theme/tokens.dart';
import '../admin/members_screen.dart';
import '../common/estimated.dart';
import '../feed/feed_providers.dart';
import '../ponds/pond_overview.dart';
import '../sync/sync_badge.dart';
import '../sync/sync_screen.dart';

/// French or Malagasy, for this account on every phone (SPEC §9).
Future<void> chooseLanguage(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final code = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.moreLanguage),
      children: [
        for (final (code, label) in [
          ('fr', l10n.languageFrench),
          ('mg', l10n.languageMalagasy),
        ])
          SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            onPressed: () => Navigator.pop(context, code),
            child: Text(label),
          ),
      ],
    ),
  );
  if (code == null) return;
  ref.read(localeControllerProvider.notifier).set(Locale(code));
  await ref.read(memberRepositoryProvider).setOwnLocale(code);
}

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final session = ref.watch(sessionProvider).value;
    final admin = session?.isAdmin ?? false;
    final sales = session?.isSales ?? false;
    final open = ref
        .watch(batchSummariesProvider)
        .value
        ?.where((s) => s.batch.status != BatchStatus.closed)
        .length;
    final stock = ref.watch(feedStockProvider).value;
    final counts = ref.watch(syncCountsProvider).value;
    final last = ref.watch(lastSyncProvider);
    final me = session == null
        ? null
        : ref
              .watch(membersProvider)
              .value
              ?.where((m) => m.id == session.userId)
              .firstOrNull;
    final text = Theme.of(context).textTheme;
    final c = context.dobo;

    Widget heading(String key, String title) => Padding(
      key: ValueKey('more-group-$key'),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(title, style: text.titleSmall?.copyWith(color: c.inkMuted)),
    );
    Widget row(
      Widget icon,
      String title,
      VoidCallback onTap, {
      Widget? summary,
      bool chevron = true,
    }) => ListTile(
      minTileHeight: 56,
      leading: icon,
      title: Text(title),
      // Under the title, not beside it: on a 360 dp phone the two side by
      // side cut "Synchronisation" mid-word.
      subtitle: summary == null
          ? null
          : DefaultTextStyle.merge(
              style: text.bodySmall?.copyWith(color: c.ink),
              child: summary,
            ),
      trailing: chevron ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );

    final syncSummary = switch ((counts, last)) {
      ((rejected: final r, pending: _)?, _) when r > 0 => Text(
        l10n.syncSummaryRejected(formatCount(r, locale)),
        style: TextStyle(color: c.danger),
      ),
      (_, AsyncData(value: null)) => Text(l10n.syncSummaryNever),
      ((pending: final p, rejected: _)?, AsyncData()) when p > 0 => Text(
        l10n.syncSummaryPending(formatCount(p, locale)),
      ),
      (_?, AsyncData()) => Text(l10n.syncSummaryUpToDate),
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMore)),
      body: ListView(
        children: [
          heading('farm', l10n.moreGroupFarm),
          row(
            const Icon(Icons.set_meal),
            l10n.moreBatches,
            () => context.go('/more/batches'),
            summary: open == null ? null : Text(l10n.moreBatchesSummary(open)),
          ),
          row(
            const Icon(Icons.inventory_2),
            l10n.moreFeed,
            () => context.go('/more/feed'),
            summary: stock == null
                ? null
                : stock.daysLeft == null
                ? Text(formatKg(stock.onHandG, locale))
                : EstimatedLabel(
                    value: l10n.feedDaysLeftShort(
                      formatDecimal(stock.daysLeft!, locale, decimals: 0),
                    ),
                    trailing: ', ${formatKg(stock.onHandG, locale)}',
                  ),
          ),
          if (sales)
            row(
              const Icon(Icons.storefront),
              l10n.moreSales,
              () => context.go('/more/sales'),
            ),
          heading('sheets', l10n.moreGroupSheets),
          row(
            const Icon(Icons.edit_note),
            l10n.transcription,
            () => context.go('/more/transcription'),
          ),
          row(
            const Icon(Icons.print),
            l10n.morePaper,
            () => context.go('/more/paper'),
          ),
          row(
            const Icon(Icons.file_download),
            l10n.moreExports,
            () => context.go('/more/exports'),
          ),
          heading('phone', l10n.moreGroupPhone),
          row(
            const SyncBadge(child: Icon(Icons.sync)),
            l10n.moreSync,
            () => context.go('/more/sync'),
            summary: syncSummary,
          ),
          row(const Icon(Icons.agriculture), l10n.workerMode, () {
            ref.read(localeControllerProvider.notifier).set(const Locale('mg'));
            context.go('/worker');
          }),
          row(
            const Icon(Icons.account_circle),
            l10n.moreAccount,
            () => context.go('/more/account'),
            summary: me == null ? null : Text(me.name),
          ),
          row(
            const Icon(Icons.translate),
            l10n.moreLanguage,
            () => chooseLanguage(context, ref),
            summary: Text(
              locale.languageCode == 'mg'
                  ? l10n.languageMalagasy
                  : l10n.languageFrench,
            ),
          ),
          if (admin) ...[
            heading('admin', l10n.moreGroupAdmin),
            row(
              const Icon(Icons.admin_panel_settings),
              l10n.moreAdmin,
              () => context.go('/more/admin'),
            ),
            row(
              const Icon(Icons.people),
              l10n.morePeople,
              () => context.go('/more/people'),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
