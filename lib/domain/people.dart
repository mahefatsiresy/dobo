/// An account as far as "who" is concerned: its name and the `Person` it
/// belongs to, if linked.
class AccountRef {
  const AccountRef({required this.name, this.personId});

  final String name;
  final String? personId;
}

/// Names for the people and accounts on records. A record's observer is
/// `observed_by` when set (someone else saw it), otherwise the person whose
/// account entered it (CLAUDE.md §Conventions, "Who").
class PeopleDirectory {
  const PeopleDirectory({this.people = const {}, this.accounts = const {}});

  /// Person id → name.
  final Map<String, String> people;

  /// Member id → account.
  final Map<String, AccountRef> accounts;

  /// One key per human: the person id, or `account:<id>` for an account
  /// with no person yet.
  String observerKey({String? observedBy, required String enteredBy}) =>
      observedBy ?? accounts[enteredBy]?.personId ?? 'account:$enteredBy';

  /// The observer's name; null when this phone doesn't know them. Never the
  /// typist's name for a record someone else observed.
  String? observerName({String? observedBy, required String enteredBy}) {
    if (observedBy != null) return people[observedBy];
    final account = accounts[enteredBy];
    if (account == null) return null;
    return people[account.personId] ?? account.name;
  }
}
