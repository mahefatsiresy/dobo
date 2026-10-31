import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../alerts/alert_providers.dart';
import '../sync/sync_badge.dart';

/// Member navigation (SPEC §6). Tabs are added with the milestones that
/// build them.
class MemberShell extends ConsumerWidget {
  const MemberShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final danger = ref.watch(dangerCountProvider);
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
            icon: const Icon(Icons.assignment),
            label: l10n.tabVisit,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: danger > 0,
              label: Text('$danger'),
              child: const Icon(Icons.notifications),
            ),
            label: l10n.tabAlerts,
          ),
          NavigationDestination(
            icon: const SyncBadge(child: Icon(Icons.menu)),
            label: l10n.tabMore,
          ),
        ],
      ),
    );
  }
}
