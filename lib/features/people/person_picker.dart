import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import 'people_providers.dart';

/// Opens the person picker; the picked person's id, or null on back.
Future<String?> pickPerson(BuildContext context, {String? current}) =>
    context.push<String>(
      Uri(
        path: '/more/people/pick',
        queryParameters: {'current': ?current},
      ).toString(),
    );

/// Active people, those without an account first (the workers whose paper
/// sheets are copied), then members' people, each group by name.
List<Person> pickablePeople(List<Person> people, Map<String, Object> roles) {
  int byName(Person a, Person b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  final active = people.where((p) => p.active);
  return [
    ...active.where((p) => roles[p.id] == null).toList()..sort(byName),
    ...active.where((p) => roles[p.id] != null).toList()..sort(byName),
  ];
}

/// A page of people, one tap to pick (docs/design.md §Step 7b).
class PersonPickerScreen extends ConsumerWidget {
  const PersonPickerScreen({super.key, this.current});

  final String? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.dobo;
    final people = ref.watch(peopleProvider).value;
    final roles = ref.watch(personRolesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sheetOf)),
      body: people == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final p in pickablePeople(people, roles)) ...[
                  ListTile(
                    minTileHeight: 56,
                    title: Text(personLabel(l10n, p, roles[p.id])),
                    trailing: p.id == current
                        ? Icon(Icons.check, color: c.ink)
                        : null,
                    onTap: () => context.pop(p.id),
                  ),
                  Divider(height: 1, color: c.line),
                ],
              ],
            ),
    );
  }
}
