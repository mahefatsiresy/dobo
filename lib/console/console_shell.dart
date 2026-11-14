import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'console_config.dart';
import 'console_providers.dart';
import 'language_switch.dart';

/// The admin pages' frame (SPEC F16): a side menu, sign-out at its foot,
/// and the page in a column no wider than [consoleMaxWidth].
class ConsoleShell extends ConsumerWidget {
  const ConsoleShell({super.key, required this.child});

  final Widget child;

  static const sections = [
    ('/association', 'navAssociation', Icons.home_work_outlined),
    ('/groupes', 'navGroups', Icons.groups_outlined),
    ('/membres', 'navMembers', Icons.badge_outlined),
    ('/personnes', 'navPeople', Icons.people_outline),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final at = GoRouterState.of(context).matchedLocation;
    final labels = [
      l10n.consoleNavAssociation,
      l10n.consoleNavGroups,
      l10n.consoleNavMembers,
      l10n.consoleNavPeople,
    ];
    final selected = sections.indexWhere((s) => at.startsWith(s.$1));
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: selected < 0 ? null : selected,
            onDestinationSelected: (i) => context.go(sections[i].$1),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.consoleTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            destinations: [
              for (final (i, s) in sections.indexed)
                NavigationRailDestination(
                  icon: Icon(s.$3, key: Key(s.$2)),
                  label: Text(labels[i]),
                ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ConsoleLanguageSwitch(),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const Key('consoleSignOut'),
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.consoleSignOut),
                        onPressed: () => ref.read(consoleSignOutProvider)(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: consoleMaxWidth),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
