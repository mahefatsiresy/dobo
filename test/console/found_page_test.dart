import 'package:dobo/console/console_providers.dart';
import 'package:dobo/console/console_router.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:dobo/sync/sync_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'console_test_app.dart';
import 'fake_console_api.dart';

/// A console API whose founding answers with [error] once.
class _Refusing extends FakeConsoleApi {
  _Refusing(this.error);

  Object? error;

  @override
  Future<void> foundAssociation(f) async {
    final e = error;
    if (e != null) {
      plannedSeen.add(f);
      error = null;
      throw e;
    }
    return super.foundAssociation(f);
  }
}

void main() {
  Future<ProviderContainer> open(WidgetTester tester, FakeConsoleApi api) =>
      pumpConsole(
        tester,
        at: '/fonder',
        overrides: [consoleApiProvider.overrideWithValue(api)],
      );

  Future<void> fill(
    WidgetTester tester, {
    String password = 'motdepasse1',
    String again = 'motdepasse1',
    String note = '',
  }) async {
    Future<void> type(String key, String text) async {
      await tester.enterText(find.byKey(Key(key)), text);
      await tester.pump();
    }

    await type('foundCode', 'code-secret');
    await type('foundAssociation', 'Famille Rabe');
    await type('foundGroup', 'Branche 1');
    await type('foundName', 'Soa');
    await type('foundEmail', 'soa@a.mg');
    await type('foundPassword', password);
    await type('foundPasswordAgain', again);
    await type('foundSite', 'Ambohidratrimo');
    if (note.isNotEmpty) await type('foundNote', note);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('foundSubmit')));
    await tester.tap(find.byKey(const Key('foundSubmit')));
    await tester.pumpAndSettle();
  }

  String location(ProviderContainer c) =>
      c.read(consoleRouterProvider).state.matchedLocation;

  testWidgets('founding with every field calls the API once and lands on '
      'Membres', (tester) async {
    final api = FakeConsoleApi();
    final c = await open(tester, api);
    await fill(tester, note: 'Près du lac');
    await submit(tester);

    final f = api.foundings.single;
    expect(
      (f.code, f.associationName, f.groupName, f.founderName, f.email),
      ('code-secret', 'Famille Rabe', 'Branche 1', 'Soa', 'soa@a.mg'),
    );
    expect((f.siteName, f.locationNote), ('Ambohidratrimo', 'Près du lac'));
    expect(location(c), '/membres');
  });

  testWidgets('a short password or a mismatch blocks the button with the '
      'reason', (tester) async {
    await open(tester, FakeConsoleApi());
    await fill(tester, password: 'court', again: 'court');
    await tester.ensureVisible(find.byKey(const Key('foundSubmit')));
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('foundSubmit'))).onPressed,
      isNull,
    );
    expect(find.text('8 caractères au moins'), findsWidgets);

    await fill(tester, again: 'autrechose');
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('foundSubmit'))).onPressed,
      isNull,
    );
    expect(find.text('Les deux mots de passe diffèrent'), findsOneWidget);
  });

  testWidgets('bad_code says the code is wrong or already used', (tester) async {
    await open(tester, _Refusing(const AuthFailed('bad_code')));
    await fill(tester);
    await submit(tester);
    expect(find.text('Code de fondation faux ou déjà utilisé'), findsOneWidget);
  });

  testWidgets('login_taken says the email is already in use', (tester) async {
    await open(tester, _Refusing(const AuthFailed('login_taken')));
    await fill(tester);
    await submit(tester);
    expect(find.text('Cet identifiant est déjà utilisé'), findsOneWidget);
  });

  testWidgets('a retry after no network sends the same planned ids', (
    tester,
  ) async {
    final api = _Refusing(SyncOffline());
    final c = await open(tester, api);
    await fill(tester);
    await submit(tester);
    expect(find.text('Connexion nécessaire'), findsOneWidget);
    expect(location(c), '/fonder');

    // The fake records only the founding that went through; compare it with
    // the ids the page planned before the first try.
    await submit(tester);
    expect(location(c), '/membres');
    final f = api.foundings.single;
    expect(f.personId, isNot(isEmpty));
    expect(api.plannedSeen, hasLength(2));
    final [first, second] = api.plannedSeen;
    expect(
      (second.associationId, second.memberId, second.personId),
      (first.associationId, first.memberId, first.personId),
    );
  });

  testWidgets('the location note is optional', (tester) async {
    final api = FakeConsoleApi();
    await open(tester, api);
    await fill(tester);
    await submit(tester);
    expect(api.foundings.single.locationNote, isNull);
  });

  testWidgets('the sign-in page links to the founding page', (tester) async {
    final c = await pumpConsole(
      tester,
      at: '/connexion',
      overrides: [consoleApiProvider.overrideWithValue(FakeConsoleApi())],
    );
    await tester.tap(find.text('Fonder une association'));
    await tester.pumpAndSettle();
    expect(location(c), '/fonder');
  });
}
