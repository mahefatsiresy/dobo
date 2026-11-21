import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../db/database.dart';
import '../../theme/tokens.dart';
import '../common/folded_section.dart';
import 'people_providers.dart';

/// The people records name as observers: active ones by name, inactive
/// ones folded at the foot (docs/design.md §Step 7b).
class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.dobo;
    final people = [...?ref.watch(peopleProvider).value]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final roles = ref.watch(personRolesProvider);
    Widget row(Person p) => ListTile(
      minTileHeight: 56,
      title: Text(personLabel(l10n, p, roles[p.id])),
      subtitle: p.phone == null ? null : Text(p.phone!),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/more/people/${p.id}'),
    );
    final inactive = people.where((p) => !p.active).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.morePeople)),
      body: ListView(
        children: [
          if (people.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.peopleEmpty),
            ),
          for (final p in people.where((p) => p.active)) ...[
            row(p),
            Divider(height: 1, color: c.line),
          ],
          if (inactive.isNotEmpty) ...[
            FoldedSection(
              title: l10n.membersInactive,
              summary: l10n.inactiveCount(inactive.length),
              builder: (context) =>
                  Column(children: [for (final p in inactive) row(p)]),
            ),
            Divider(height: 1, color: c.line),
          ],
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.person_add),
            title: Text(l10n.personAdd),
            onTap: () => context.go('/more/people/new'),
          ),
        ],
      ),
    );
  }
}
