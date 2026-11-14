import 'package:dobo/console/console_providers.dart';
import 'package:dobo/console/console_router.dart';
import 'package:dobo/console/data/activity_store.dart';
import 'package:dobo/console/idle_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'console_test_app.dart';
import 'fake_console_api.dart';

void main() {
  Future<List<int>> guard(WidgetTester tester) async {
    final calls = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: IdleGuard(
          onIdle: () => calls.add(1),
          child: const Scaffold(body: Center(child: Text('page'))),
        ),
      ),
    );
    return calls;
  }

  testWidgets('30 minutes without input calls onIdle once', (tester) async {
    final calls = await guard(tester);
    await tester.pump(const Duration(minutes: 29, seconds: 59));
    expect(calls, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, [1]);
    await tester.pump(const Duration(minutes: 60));
    expect(calls, [1]);
  });

  testWidgets('a tap at 29 minutes restarts the count', (tester) async {
    final calls = await guard(tester);
    await tester.pump(const Duration(minutes: 29));
    await tester.tap(find.text('page'));
    await tester.pump(const Duration(minutes: 1));
    expect(calls, isEmpty);
    await tester.pump(const Duration(minutes: 29));
    expect(calls, [1]);
  });

  testWidgets('a key press restarts the count', (tester) async {
    final calls = await guard(tester);
    await tester.pump(const Duration(minutes: 29));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(minutes: 1));
    expect(calls, isEmpty);
  });

  testWidgets('after idle the sign-in page shows the idle notice', (
    tester,
  ) async {
    final api = FakeConsoleApi(me: consoleAdmin())..signedIn = true;
    final c = await pumpConsole(
      tester,
      at: '/membres',
      overrides: [consoleApiProvider.overrideWithValue(api)],
    );
    await tester.pump(const Duration(minutes: 30));
    await tester.pumpAndSettle();
    expect(api.signedOut, true);
    expect(c.read(consoleRouterProvider).state.matchedLocation, '/connexion');
    expect(
      find.text('Déconnecté après 30 minutes sans activité.'),
      findsOneWidget,
    );
  });

  group('the last activity survives a reload or a closed tab', () {
    final now = DateTime.utc(2026, 11, 14, 12);

    Future<FakeConsoleApi> reopen(
      WidgetTester tester,
      MemoryActivityStore store,
    ) async {
      final api = FakeConsoleApi(me: consoleAdmin())..signedIn = true;
      await pumpConsole(
        tester,
        at: '/membres',
        overrides: [
          consoleApiProvider.overrideWithValue(api),
          consoleActivityProvider.overrideWithValue(store),
          consoleClockProvider.overrideWithValue(() => now),
        ],
      );
      return api;
    }

    testWidgets('a session reopened after 31 minutes without use is signed '
        'out with the idle notice', (tester) async {
      final store = MemoryActivityStore()
        ..last = now.subtract(const Duration(minutes: 31));
      final api = await reopen(tester, store);
      expect(api.signedOut, true);
      expect(
        find.text('Déconnecté après 30 minutes sans activité.'),
        findsOneWidget,
      );
    });

    testWidgets('a session used 10 minutes ago stays open', (tester) async {
      final store = MemoryActivityStore()
        ..last = now.subtract(const Duration(minutes: 10));
      final api = await reopen(tester, store);
      expect(api.signedOut, false);
      expect(find.byKey(const Key('navMembers')), findsOneWidget);
    });

    testWidgets('a tap is saved as the last activity', (tester) async {
      final store = MemoryActivityStore()
        ..last = now.subtract(const Duration(minutes: 10));
      await reopen(tester, store);
      await tester.tap(find.byKey(const Key('navGroups')));
      await tester.pumpAndSettle();
      expect(store.last, now);
    });
  });
}
