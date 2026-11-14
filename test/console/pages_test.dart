import 'package:dobo/console/console_providers.dart';
import 'package:dobo/console/data/console_api.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'console_test_app.dart';
import 'fake_console_api.dart';

/// The association, groups and people pages (SPEC F16).
void main() {
  late FakeConsoleApi api;

  setUp(() {
    api = FakeConsoleApi(me: consoleAdmin())..signedIn = true;
    api.memberRows.add(
      const MemberRow(
        id: 'm1',
        name: 'Soa',
        groupId: null,
        personId: null,
        role: MemberRole.member,
        isAdmin: true,
        isSales: false,
        active: true,
        locale: 'fr',
        login: 'soa@a.mg',
      ),
    );
  });

  Future<void> open(WidgetTester tester, String at) => pumpConsole(
    tester,
    at: at,
    overrides: [consoleApiProvider.overrideWithValue(api)],
  );

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  testWidgets('renaming the association shows the new name', (tester) async {
    await open(tester, '/association');
    expect(find.text('Famille Rabe'), findsWidgets);
    await tap(tester, find.byKey(const Key('renameAssociation')));
    await type(tester, 'nameField', 'Famille Rabe-Soa');
    await tap(tester, find.byKey(const Key('dialogSave')));
    expect(api.associationName, 'Famille Rabe-Soa');
    expect(find.text('Famille Rabe-Soa'), findsWidgets);
  });

  testWidgets('a new group appears in the table', (tester) async {
    await open(tester, '/groupes');
    await tap(tester, find.byKey(const Key('newGroup')));
    await type(tester, 'nameField', 'Branche Rabe');
    await tap(tester, find.byKey(const Key('dialogSave')));
    expect(api.groupRows.single.name, 'Branche Rabe');
    expect(find.text('Branche Rabe'), findsOneWidget);
  });

  testWidgets('renaming a group to blank is refused', (tester) async {
    api.groupRows.add(const GroupRow(id: 'g1', name: 'Branche Rabe'));
    await open(tester, '/groupes');
    await tap(tester, find.byKey(const Key('edit-g1')));
    await type(tester, 'nameField', '   ');
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('dialogSave'))).onPressed,
      isNull,
    );
  });

  testWidgets('a new person appears; editing keeps their id', (tester) async {
    await open(tester, '/personnes');
    await tap(tester, find.byKey(const Key('newPerson')));
    await type(tester, 'nameField', 'Bema');
    await type(tester, 'phoneField', '034 00 000 00');
    await tap(tester, find.byKey(const Key('dialogSave')));
    final p = api.peopleRows.single;
    expect((p.name, p.phone, p.active), ('Bema', '034 00 000 00', true));
    expect(find.text('Bema'), findsOneWidget);

    await tap(tester, find.byKey(Key('edit-${p.id}')));
    await type(tester, 'nameField', 'Bema Rakoto');
    await tap(tester, find.byKey(const Key('dialogSave')));
    expect(api.peopleRows.single.id, p.id);
    expect(api.peopleRows.single.name, 'Bema Rakoto');
  });

  testWidgets('a write with no network shows the offline message and keeps '
      'the dialog open with what was typed', (tester) async {
    await open(tester, '/groupes');
    await tap(tester, find.byKey(const Key('newGroup')));
    await type(tester, 'nameField', 'Branche Rabe');
    api.offline = true;
    await tap(tester, find.byKey(const Key('dialogSave')));
    expect(find.text('Connexion nécessaire'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Branche Rabe'), findsOneWidget);
    expect(api.groupRows, isEmpty);
  });

  testWidgets("switching to mg saves it on the admin's own member row and "
      'relabels the menu', (tester) async {
    await open(tester, '/membres');
    await tap(tester, find.byKey(const Key('consoleLanguage-mg')));
    expect(api.memberRows.single.locale, 'mg');
    expect(find.text('Mpikambana'), findsWidgets);
  });
}
