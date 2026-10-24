import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Member navigation (SPEC §6). Tabs are added with the milestones that
/// build them.
class MemberShell extends StatelessWidget {
  const MemberShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.water),
            label: l10n.tabPonds,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu),
            label: l10n.tabMore,
          ),
        ],
      ),
    );
  }
}
