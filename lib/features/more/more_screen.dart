import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMore)),
      body: ListView(
        children: [
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
