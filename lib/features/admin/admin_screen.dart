import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import 'members_screen.dart';

/// Admin tools (SPEC F14): members and accounts, branches, settings, each
/// with what it holds (docs/design.md §Step 7b).
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final members = ref.watch(membersProvider).value;
    final groups = ref.watch(groupsProvider).value;
    final overrides = ref.watch(settingOverridesProvider).value;
    final active = members?.where((m) => m.active).toList();
    Widget tile(IconData icon, String title, String? summary, String to) =>
        ListTile(
          minTileHeight: 56,
          leading: Icon(icon),
          title: Text(title),
          subtitle: summary == null
              ? null
              : Text(summary, style: text.bodySmall?.copyWith(color: c.ink)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(to),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreAdmin)),
      body: ListView(
        children: [
          tile(
            Icons.group,
            l10n.adminMembers,
            active == null
                ? null
                : l10n.adminMembersSummary(
                    active.length,
                    l10n.adminWorkersCount(
                      active.where((m) => m.role == MemberRole.worker).length,
                    ),
                  ),
            '/more/admin/members',
          ),
          tile(
            Icons.family_restroom,
            l10n.adminGroups,
            groups == null ? null : l10n.adminGroupsSummary(groups.length),
            '/more/admin/groups',
          ),
          tile(
            Icons.tune,
            l10n.adminSettings,
            overrides == null
                ? null
                : l10n.adminSettingsSummary(overrides.length),
            '/more/admin/settings',
          ),
        ],
      ),
    );
  }
}
