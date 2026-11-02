import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/people.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';

final peopleProvider = StreamProvider<List<Person>>(
  (ref) => ref.watch(personRepositoryProvider).watchAll(),
);

final _accountsProvider = StreamProvider<List<Member>>(
  (ref) => ref.watch(memberRepositoryProvider).watchAll(),
);

/// Names for "who observed" on records (CLAUDE.md "Who").
final peopleDirectoryProvider = Provider<AsyncValue<PeopleDirectory>>((ref) {
  final people = ref.watch(peopleProvider);
  final accounts = ref.watch(_accountsProvider);
  if (!people.hasValue || !accounts.hasValue) return const AsyncLoading();
  return AsyncData(
    PeopleDirectory(
      people: {for (final p in people.requireValue) p.id: p.name},
      accounts: {
        for (final m in accounts.requireValue)
          m.id: AccountRef(name: m.name, personId: m.personId),
      },
    ),
  );
});

/// The role of the account each linked person belongs to.
final personRolesProvider = Provider<Map<String, MemberRole>>(
  (ref) => {
    for (final m in ref.watch(_accountsProvider).value ?? const <Member>[])
      if (m.personId != null) m.personId!: m.role,
  },
);

/// A person's name, with the role of their account when they have one.
String personLabel(AppLocalizations l10n, Person p, MemberRole? role) =>
    switch (role) {
      null => p.name,
      MemberRole.member => l10n.personOfMember(p.name),
      MemberRole.worker => l10n.personOfWorker(p.name),
    };
