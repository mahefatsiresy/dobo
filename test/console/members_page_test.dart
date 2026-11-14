import 'package:dobo/console/console_providers.dart';
import 'package:dobo/console/data/console_api.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'console_test_app.dart';
import 'fake_console_api.dart';

/// The members page (SPEC F14, F16): accounts, deactivation and reset.
void main() {
  late FakeConsoleApi api;

  MemberRow member(
    String id,
    String name, {
    MemberRole role = MemberRole.member,
    bool isAdmin = false,
    bool active = true,
    String? login,
  }) => MemberRow(
    id: id,
    name: name,
    groupId: null,
    personId: null,
    role: role,
    isAdmin: isAdmin,
    isSales: false,
    active: active,
    locale: role == MemberRole.worker ? 'mg' : 'fr',
    login: login ?? '$id@a.mg',
  );

  setUp(() {
    api = FakeConsoleApi(me: consoleAdmin())..signedIn = true;
    api.memberRows.addAll([
      member('m1', 'Soa', isAdmin: true),
      member('w1', 'Rakoto', role: MemberRole.worker, login: 'rakoto'),
    ]);
  });

  Future<void> open(WidgetTester tester) => pumpConsole(
    tester,
    at: '/membres',
    overrides: [consoleApiProvider.overrideWithValue(api)],
  );

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> newWorker(WidgetTester tester, {String pin = '123456'}) async {
    await tap(tester, find.byKey(const Key('newAccount')));
    await type(tester, 'accountName', 'Bema');
    await tap(tester, find.byKey(const Key('role-worker')));
    await type(tester, 'accountLogin', 'bema');
    await type(tester, 'accountSecret', pin);
    await type(tester, 'accountSecretAgain', pin);
  }

  FilledButton button(WidgetTester tester, String key) =>
      tester.widget<FilledButton>(find.byKey(Key(key)));

  testWidgets('a new worker account is created with a PIN and shows in the '
      'table', (tester) async {
    await open(tester);
    await newWorker(tester);
    await tap(tester, find.byKey(const Key('accountSave')));
    final a = api.createdAccounts.single;
    expect(
      (a.name, a.role, a.login, a.secret),
      ('Bema', MemberRole.worker, 'bema', '123456'),
    );
    expect(find.text('Bema'), findsOneWidget);
  });

  testWidgets("the worker's language defaults to mg, a member's to fr", (
    tester,
  ) async {
    await open(tester);
    await newWorker(tester);
    await tap(tester, find.byKey(const Key('accountSave')));
    expect(api.createdAccounts.last.locale, 'mg');

    await tap(tester, find.byKey(const Key('newAccount')));
    await type(tester, 'accountName', 'Hery');
    await type(tester, 'accountLogin', 'hery@a.mg');
    await type(tester, 'accountSecret', 'motdepasse1');
    await type(tester, 'accountSecretAgain', 'motdepasse1');
    await tap(tester, find.byKey(const Key('accountSave')));
    expect(api.createdAccounts.last.locale, 'fr');
  });

  testWidgets('a 5-digit PIN blocks the button', (tester) async {
    await open(tester);
    await newWorker(tester, pin: '12345');
    expect(button(tester, 'accountSave').onPressed, isNull);
  });

  testWidgets('login_taken keeps the dialog open; the retry sends the same '
      'memberId', (tester) async {
    await open(tester);
    await newWorker(tester);
    api.failNextWrite = 'login_taken';
    await tap(tester, find.byKey(const Key('accountSave')));
    expect(find.byKey(const Key('accountSave')), findsOneWidget);
    expect(find.text('Cet identifiant est déjà utilisé'), findsOneWidget);
    await tap(tester, find.byKey(const Key('accountSave')));
    expect(api.createdAccounts, hasLength(1));
    expect(api.accountAttempts, hasLength(2));
    expect(
      api.accountAttempts.first.memberId,
      api.accountAttempts.last.memberId,
    );
  });

  testWidgets('a server refusing with last_admin shows why and the table is '
      'unchanged', (tester) async {
    api.memberRows.add(member('m2', 'Hery', isAdmin: true));
    await open(tester);
    await tap(tester, find.byKey(const Key('toggle-m2')));
    api.failNextWrite = 'last_admin';
    await tap(tester, find.byKey(const Key('confirmToggle')));
    expect(
      find.text('Il doit rester au moins un administrateur'),
      findsOneWidget,
    );
    expect(api.memberRows.singleWhere((m) => m.id == 'm2').active, true);
  });

  testWidgets("an admin can't change their own role, admin flag or activity", (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('toggle-m1')), findsNothing);
    await tap(tester, find.byKey(const Key('edit-m1')));
    final admin = tester.widget<SwitchListTile>(
      find.byKey(const Key('accountAdmin')),
    );
    expect(admin.onChanged, isNull);
  });

  testWidgets('deactivating asks first, then shows the member inactive', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.byKey(const Key('toggle-w1')));
    expect(api.memberRows.singleWhere((m) => m.id == 'w1').active, true);
    await tap(tester, find.byKey(const Key('confirmToggle')));
    expect(api.memberRows.singleWhere((m) => m.id == 'w1').active, false);
    expect(find.byKey(const Key('inactive-w1')), findsOneWidget);
  });

  testWidgets("editing changes a worker's group and role", (tester) async {
    api.groupRows.add(const GroupRow(id: 'g1', name: 'Branche Rabe'));
    await open(tester);
    await tap(tester, find.byKey(const Key('edit-w1')));
    await tap(tester, find.byKey(const Key('accountGroup')));
    await tap(tester, find.text('Branche Rabe').last);
    await tap(tester, find.byKey(const Key('role-member')));
    await tap(tester, find.byKey(const Key('accountSave')));
    final w = api.memberRows.singleWhere((m) => m.id == 'w1');
    expect((w.groupId, w.role), ('g1', MemberRole.member));
  });

  testWidgets('resetting a PIN calls the API with the member and the new PIN '
      'and says done', (tester) async {
    await open(tester);
    await tap(tester, find.byKey(const Key('reset-w1')));
    await type(tester, 'consoleNewSecret', '654321');
    await type(tester, 'consoleNewSecretAgain', '654321');
    await tap(tester, find.byKey(const Key('consoleConfirmReset')));
    expect(api.resets, [('w1', '654321')]);
    expect(find.text('Code PIN changé'), findsOneWidget);
  });
}
