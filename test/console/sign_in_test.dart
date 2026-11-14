import 'package:dobo/console/console_providers.dart';
import 'package:dobo/console/console_router.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'console_test_app.dart';
import 'fake_console_api.dart';

void main() {
  Future<ProviderContainer> signIn(
    WidgetTester tester,
    FakeConsoleApi api, {
    String password = 'motdepasse1',
  }) async {
    final c = await pumpConsole(
      tester,
      at: '/connexion',
      overrides: [consoleApiProvider.overrideWithValue(api)],
    );
    await tester.enterText(find.byKey(const Key('consoleEmail')), 'soa@a.mg');
    await tester.enterText(find.byKey(const Key('consolePassword')), password);
    await tester.tap(find.byKey(const Key('consoleSignIn')));
    await tester.pumpAndSettle();
    return c;
  }

  String location(ProviderContainer c) =>
      c.read(consoleRouterProvider).state.matchedLocation;

  testWidgets('an admin signs in and lands on Membres', (tester) async {
    final api = FakeConsoleApi(me: consoleAdmin());
    final c = await signIn(tester, api);
    expect(location(c), '/membres');
    expect(find.byKey(const Key('navMembers')), findsOneWidget);
  });

  testWidgets('a worker who signs in is signed out with the admins-only '
      'message', (tester) async {
    final api = FakeConsoleApi(
      me: consoleAdmin(role: MemberRole.worker, isAdmin: false),
    );
    final c = await signIn(tester, api);
    expect(api.signedOut, true);
    expect(location(c), '/connexion');
    expect(find.byKey(const Key('navMembers')), findsNothing);
    expect(
      find.text('La console est réservée aux administrateurs.'),
      findsOneWidget,
    );
  });

  testWidgets('a member without the admin flag is signed out with the '
      'admins-only message', (tester) async {
    final api = FakeConsoleApi(me: consoleAdmin(isAdmin: false));
    await signIn(tester, api);
    expect(api.signedOut, true);
    expect(
      find.text('La console est réservée aux administrateurs.'),
      findsOneWidget,
    );
  });

  testWidgets('a wrong password says so and stays on the page', (tester) async {
    final api = FakeConsoleApi(me: consoleAdmin(), password: 'motdepasse1');
    final c = await signIn(tester, api, password: 'pasbon123');
    expect(location(c), '/connexion');
    expect(find.text('Identifiant ou mot de passe incorrect'), findsOneWidget);
  });

  testWidgets('no network says so', (tester) async {
    final api = FakeConsoleApi(me: consoleAdmin())..offline = true;
    await signIn(tester, api);
    expect(find.text('Connexion nécessaire'), findsOneWidget);
  });

  testWidgets('an open session of a non-admin is signed out on load', (
    tester,
  ) async {
    final api = FakeConsoleApi(me: consoleAdmin(isAdmin: false))
      ..signedIn = true;
    final c = await pumpConsole(
      tester,
      at: '/membres',
      overrides: [consoleApiProvider.overrideWithValue(api)],
    );
    expect(location(c), '/connexion');
    expect(api.signedOut, true);
  });

  testWidgets('signed out, an admin page sends to the sign-in page', (
    tester,
  ) async {
    final c = await pumpConsole(
      tester,
      at: '/groupes',
      overrides: [
        consoleApiProvider.overrideWithValue(FakeConsoleApi(me: consoleAdmin())),
      ],
    );
    expect(location(c), '/connexion');
  });

  testWidgets('Se déconnecter signs out and shows the sign-in page', (
    tester,
  ) async {
    final api = FakeConsoleApi(me: consoleAdmin())..signedIn = true;
    final c = await pumpConsole(
      tester,
      at: '/membres',
      overrides: [consoleApiProvider.overrideWithValue(api)],
    );
    await tester.tap(find.byKey(const Key('consoleSignOut')));
    await tester.pumpAndSettle();
    expect(api.signedOut, true);
    expect(location(c), '/connexion');
  });
}
