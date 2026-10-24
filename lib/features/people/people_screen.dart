import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'people_providers.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final people = ref.watch(peopleProvider).value ?? const [];
    final grey = Theme.of(context).disabledColor;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.morePeople)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/more/people/new'),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.add),
      ),
      body: people.isEmpty
          ? Center(child: Text(l10n.peopleEmpty))
          : ListView(
              children: [
                for (final p in people)
                  ListTile(
                    minTileHeight: 56,
                    leading: const Icon(Icons.person),
                    title: Text(p.name),
                    subtitle: p.active
                        ? (p.phone == null ? null : Text(p.phone!))
                        : Text(l10n.personInactive),
                    textColor: p.active ? null : grey,
                    iconColor: p.active ? null : grey,
                    onTap: () => context.go('/more/people/${p.id}'),
                  ),
              ],
            ),
    );
  }
}
