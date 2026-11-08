import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../locale_controller.dart';
import '../sync/sync_badge.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  /// French or Malagasy, for this account on every phone (SPEC §9).
  Future<void> _language(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final admin = ref.watch(sessionProvider).value?.isAdmin ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMore)),
      body: ListView(
        children: [
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.account_circle),
            title: Text(l10n.moreAccount),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/account'),
          ),
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.translate),
            title: Text(l10n.moreLanguage),
            onTap: () => _language(context, ref),
          ),
          if (admin)
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(l10n.moreAdmin),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/more/admin'),
            ),
          ListTile(
            minTileHeight: 56,
            leading: const SyncBadge(child: Icon(Icons.sync)),
            title: Text(l10n.moreSync),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/sync'),
          ),
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.agriculture),
            title: Text(l10n.workerMode),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ref
                  .read(localeControllerProvider.notifier)
                  .set(const Locale('mg'));
              context.go('/worker');
            },
          ),
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.edit_note),
            title: Text(l10n.transcription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/transcription'),
          ),
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.print),
            title: Text(l10n.morePaper),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/paper'),
          ),
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.set_meal),
            title: Text(l10n.moreBatches),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/batches'),
          ),
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.inventory_2),
            title: Text(l10n.moreFeed),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/feed'),
          ),
          if (ref.watch(sessionProvider).value?.isSales ?? false)
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.storefront),
              title: Text(l10n.moreSales),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/more/sales'),
            ),
          if (admin)
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.people),
              title: Text(l10n.morePeople),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/more/people'),
            ),
        ],
      ),
    );
  }
}
