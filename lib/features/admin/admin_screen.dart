import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Admin tools (SPEC F14): members and accounts, branches, settings.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget tile(IconData icon, String title, String to) => ListTile(
      minTileHeight: 56,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(to),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreAdmin)),
      body: ListView(
        children: [
          tile(Icons.group, l10n.adminMembers, '/more/admin/members'),
          tile(Icons.family_restroom, l10n.adminGroups, '/more/admin/groups'),
        ],
      ),
    );
  }
}
