import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// An account [memberId] named [name], linked to person [personId].
Future<void> addLinkedAccount(
  WidgetTester tester,
  AppDatabase db, {
  required String memberId,
  required String personId,
  required String name,
  MemberRole role = MemberRole.member,
}) async {
  final s = (await SetupRepository(db).currentSession())!;
  await db
      .into(db.people)
      .insert(
        PeopleCompanion.insert(
          id: Value(personId),
          associationId: s.associationId,
          enteredBy: s.userId,
          deviceId: s.deviceId,
          name: name,
          syncState: const Value(SyncState.synced),
        ),
      );
  await db
      .into(db.members)
      .insert(
        MembersCompanion.insert(
          id: Value(memberId),
          associationId: s.associationId,
          enteredBy: s.userId,
          deviceId: s.deviceId,
          name: name,
          personId: Value(personId),
          role: role,
          locale: 'fr',
          syncState: const Value(SyncState.synced),
        ),
      );
  await tester.pumpAndSettle();
}

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  appTest('add a person, then mark them inactive', (tester, db) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Personnes'));
    await tapAndSettle(tester, find.text('Ajouter'));
    await tester.enterText(field('Nom'), 'Rakoto');
    await tester.enterText(field('Téléphone'), '034 00 000 00');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Rakoto'), findsOneWidget);

    await tapAndSettle(tester, find.text('Ajouter'));
    await tester.enterText(field('Nom'), 'Soa');
    await tapAndSettle(tester, find.text('Enregistrer'));

    await tapAndSettle(tester, find.text('Rakoto'));
    await tapAndSettle(tester, find.text('Actif'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    final rows = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => ((t.title! as Text).data, t.enabled))
        .toList();
    expect(rows, [('Soa', true), ('Rakoto', true)]);
    expect(find.text('Inactif'), findsOneWidget);
    final rakoto = (await db.select(db.people).get()).singleWhere(
      (p) => p.name == 'Rakoto',
    );
    expect((rakoto.active, rakoto.phone), (false, '034 00 000 00'));
  });

  appTest('a person needs a name', (tester, db) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Personnes'));
    await tapAndSettle(tester, find.text('Ajouter'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Obligatoire'), findsOneWidget);
    expect(await db.select(db.people).get(), isEmpty);
  });

  appTest("a linked person's name is read-only with the Admin hint", (
    tester,
    db,
  ) async {
    await addLinkedAccount(
      tester,
      db,
      memberId: 'm2',
      personId: 'p2',
      name: 'Hery',
    );
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Personnes'));
    expect(find.text('Hery (membre)'), findsOneWidget);
    await tapAndSettle(tester, find.text('Hery (membre)'));
    final name = tester.widget<TextField>(
      find.descendant(of: field('Nom'), matching: find.byType(TextField)),
    );
    expect(name.readOnly, isTrue);
    expect(find.text('Renommer depuis Admin › Membres'), findsOneWidget);
  });
}
