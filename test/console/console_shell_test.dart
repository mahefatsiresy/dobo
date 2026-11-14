import 'package:dobo/console/console_providers.dart';
import 'package:dobo/console/console_router.dart';
import 'package:dobo/console/console_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'console_test_app.dart';
import 'fake_console_api.dart';

void main() {
  final admin = [
    consoleApiProvider.overrideWith(
      (ref) => FakeConsoleApi(me: consoleAdmin())..signedIn = true,
    ),
  ];

  testWidgets('the shell shows the four sections and sign-out', (tester) async {
    await pumpConsole(tester, at: '/membres', overrides: admin);
    for (final key in ['navAssociation', 'navGroups', 'navMembers', 'navPeople']) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(find.byKey(const Key('consoleSignOut')), findsOneWidget);
    expect(find.byType(ConsoleShell), findsOneWidget);
  });

  testWidgets('tapping Groupes shows the groups page', (tester) async {
    await pumpConsole(tester, at: '/membres', overrides: admin);
    await tester.tap(find.byKey(const Key('navGroups')));
    await tester.pumpAndSettle();
    final router = ProviderScope.containerOf(
      tester.element(find.byType(ConsoleShell)),
    ).read(consoleRouterProvider);
    expect(router.state.matchedLocation, '/groupes');
  });
}
