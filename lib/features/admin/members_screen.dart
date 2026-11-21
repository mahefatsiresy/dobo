import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import '../common/folded_section.dart';

final membersProvider = StreamProvider<List<Member>>(
  (ref) => ref.watch(memberRepositoryProvider).watchAll(),
);

final groupsProvider = StreamProvider<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).watchAll(),
);

/// Every member by name, with their role and branch; inactive ones folded
/// at the foot (docs/design.md §Step 7b).
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.dobo;
    final me = ref.watch(sessionProvider).value?.userId;
    final members = [...?ref.watch(membersProvider).value]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final groups = {
      for (final g in ref.watch(groupsProvider).value ?? const <Group>[])
        g.id: g.name,
    };
    Widget row(Member m) => ListTile(
      minTileHeight: 56,
      title: Text(m.id == me ? l10n.memberYou(m.name) : m.name),
      subtitle: Text(
        [
          m.role == MemberRole.worker ? l10n.roleWorker : l10n.roleMember,
          if (m.isAdmin) l10n.roleAdmin,
          if (m.isSales) l10n.roleSales,
          groups[m.groupId] ?? l10n.memberNoGroup,
        ].join(', '),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/more/admin/members/${m.id}'),
    );
    final inactive = members.where((m) => !m.active).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminMembers)),
      body: ListView(
        children: [
          for (final m in members.where((m) => m.active)) ...[
            row(m),
            Divider(height: 1, color: c.line),
          ],
          if (inactive.isNotEmpty) ...[
            FoldedSection(
              title: l10n.membersInactive,
              summary: l10n.inactiveCount(inactive.length),
              builder: (context) =>
                  Column(children: [for (final m in inactive) row(m)]),
            ),
            Divider(height: 1, color: c.line),
          ],
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.person_add),
            title: Text(l10n.memberAdd),
            onTap: () => context.go('/more/admin/members/new'),
          ),
        ],
      ),
    );
  }
}
