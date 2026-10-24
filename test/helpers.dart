import 'package:dobo/app.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A widget test of the whole app on a fresh in-memory database, set up
/// unless [setUp] is false. The app is unmounted and the database closed
/// inside the test body: Drift leaves a timer when a stream query loses its
/// last listener, and closing the database from a tear-down (outside the
/// test's fake clock) would wait forever.
void appTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  bool setUp = true,
}) {
  testWidgets(description, (tester) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    if (setUp) {
      await SetupRepository(db).completeSetup(siteName: 'Ambohidratrimo');
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DoboApp(),
      ),
    );
    await tester.pumpAndSettle();
    await body(tester, db);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });
}

/// The provider container of the running app.
ProviderContainer appContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DoboApp)));

/// Scrolls [finder] into view, even in a lazily built list.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: _verticalScrollable,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Taps [finder] and waits for the app to settle.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Types [text] into [finder] and waits for the app to settle.
Future<void> enterAndSettle(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await _reveal(tester, finder);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// The innermost vertical list on screen; text fields scroll sideways.
final _verticalScrollable = find
    .byWidgetPredicate(
      (w) =>
          w is Scrollable &&
          axisDirectionToAxis(w.axisDirection) == Axis.vertical,
    )
    .last;
