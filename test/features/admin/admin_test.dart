import 'dart:async';

import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/router.dart';
import 'package:dobo/sync/providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../../sync/fake_auth_gateway.dart';

void main() {
  late FakeAuthGateway auth;

  setUp(() => auth = FakeAuthGateway(member: remoteMember(isAdmin: true)));

  Future<void> openMembers(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Administration'));
    await tapAndSettle(tester, find.text('Membres'));
  }

  appTest('the admin creates a worker account; it shows under its group', (
    tester,
    db,
  ) async {
    final s = (await appContainer(tester).read(sessionProvider.future))!;
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: const Value('g1'),
            associationId: s.associationId,
            enteredBy: s.userId,
            deviceId: s.deviceId,
            name: 'Branche Rabe',
          ),
        );
    await openMembers(tester);
    await tapAndSettle(tester, find.text('Ajouter'));
    await enterAndSettle(tester, find.byKey(const Key('memberName')), 'Rakoto');
    await tapAndSettle(tester, find.text('Ouvrier'));
    await tapAndSettle(tester, find.byKey(const Key('memberGroup')));
    await tapAndSettle(tester, find.text('Branche Rabe').last);
    await enterAndSettle(tester, find.byKey(const Key('login')), 'rakoto');
    await enterAndSettle(tester, find.byKey(const Key('secret')), '123456');
    await tapAndSettle(tester, find.byKey(const Key('saveMember')));

    final sent = auth.createdAccounts.single;
    expect(
      (sent.role, sent.login, sent.groupId),
      (MemberRole.worker, 'rakoto', 'g1'),
    );
    expect(find.text('Branche Rabe'), findsOneWidget);
    expect(find.text('Rakoto'), findsOneWidget);
  }, overrides: [authGatewayProvider.overrideWith((ref) => auth)]);

  appTest('a page opens over the tabs after Members was visited', (
    tester,
    db,
  ) async {
    await openMembers(tester);
    await tapAndSettle(tester, find.text('Étangs'));
    unawaited(appContainer(tester).read(routerProvider).push('/stock'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  appTest('a new branch saves while the keyboard closes', (tester, db) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Administration'));
    await tapAndSettle(tester, find.text('Branches'));
    await tapAndSettle(tester, find.text('Ajouter'));
    await tester.enterText(find.byType(TextField), 'Branche Rabe');
    await tapAsKeyboardCloses(tester, find.text('Enregistrer'));
    expect(tester.takeException(), isNull);
    expect(find.text('Branche Rabe'), findsOneWidget);
  });

  appTest('a 5-digit PIN keeps Save disabled', (tester, db) async {
    await openMembers(tester);
    await tapAndSettle(tester, find.text('Ajouter'));
    await enterAndSettle(tester, find.byKey(const Key('memberName')), 'Rakoto');
    await tapAndSettle(tester, find.text('Ouvrier'));
    await enterAndSettle(tester, find.byKey(const Key('login')), 'rakoto');
    await enterAndSettle(tester, find.byKey(const Key('secret')), '12345');
    final save = tester.widget<FilledButton>(
      find.byKey(const Key('saveMember')),
    );
    expect(save.onPressed, isNull);
  }, overrides: [authGatewayProvider.overrideWith((ref) => auth)]);

  appTest('a member who is not an admin sees no administration', (
    tester,
    db,
  ) async {
    expect(find.text('Ajouter un étang'), findsNothing);
    await tapAndSettle(tester, find.text('Plus'));
    expect(find.text('Administration'), findsNothing);
    expect(find.text('Personnes'), findsNothing);
  }, isAdmin: false);

  appTest('choosing Malagasy switches the app and the account', (
    tester,
    db,
  ) async {
    final s = (await appContainer(tester).read(sessionProvider.future))!;
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: Value(s.userId),
            associationId: s.associationId,
            enteredBy: s.userId,
            deviceId: s.deviceId,
            name: 'Soa',
            role: MemberRole.member,
            locale: 'fr',
            syncState: const Value(SyncState.synced),
          ),
        );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Langue'));
    await tapAndSettle(tester, find.text('Malagasy'));

    expect(
      Localizations.localeOf(tester.element(find.byType(NavigationBar))),
      const Locale('mg'),
    );
    final m = await db.select(db.members).getSingle();
    expect((m.locale, m.syncState), ('mg', SyncState.pending));
  });

  appTest('an admin cannot change their own role, admin flag or activity', (
    tester,
    db,
  ) async {
    final s = (await appContainer(tester).read(sessionProvider.future))!;
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: Value(s.userId),
            associationId: s.associationId,
            enteredBy: s.userId,
            deviceId: s.deviceId,
            name: 'Soa',
            role: MemberRole.member,
            isAdmin: const Value(true),
            locale: 'fr',
            syncState: const Value(SyncState.synced),
          ),
        );
    await openMembers(tester);
    await tapAndSettle(tester, find.text('Soa'));
    final role = tester.widget<SegmentedButton<MemberRole>>(
      find.byType(SegmentedButton<MemberRole>),
    );
    expect(role.onSelectionChanged, isNull);
    for (final label in ['Administrateur', 'Actif']) {
      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, label),
      );
      expect(tile.onChanged, isNull, reason: label);
    }
  }, overrides: [authGatewayProvider.overrideWith((ref) => auth)]);
}
