import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';

final membersProvider = StreamProvider<List<Member>>(
  (ref) => ref.watch(memberRepositoryProvider).watchAll(),
);

final groupsProvider = StreamProvider<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).watchAll(),
);

/// Every member, under their branch.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final members = ref.watch(membersProvider).value ?? const [];
    final groups = {
      for (final g in ref.watch(groupsProvider).value ?? const <Group>[])
        g.id: g.name,
    };
    final children = <Widget>[];
    String? header;
    for (final m in members) {
      final name = groups[m.groupId] ?? l10n.memberNoGroup;
      if (name != header) {
        header = name;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(name, style: Theme.of(context).textTheme.titleSmall),
          ),
        );
      }
      children.add(
        ListTile(
          minTileHeight: 56,
          enabled: m.active,
          title: Text(m.name),
          subtitle: Text(
            [
              m.role.name == 'worker' ? l10n.roleWorker : l10n.roleMember,
              if (m.isAdmin) l10n.roleAdmin,
              if (m.isSales) l10n.roleSales,
              if (!m.active) l10n.memberInactive,
            ].join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/more/admin/members/${m.id}'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminMembers)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null, // Tabs keep each branch alive: shared tags clash.
        onPressed: () => context.go('/more/admin/members/new'),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: children,
      ),
    );
  }
}
