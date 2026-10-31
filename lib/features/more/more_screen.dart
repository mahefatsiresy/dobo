import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../locale_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
            leading: const Icon(Icons.set_meal),
            title: Text(l10n.moreBatches),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/batches'),
          ),
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
