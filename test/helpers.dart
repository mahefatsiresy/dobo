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

/// Taps [finder] (scrolling to it first) and waits for the app to settle.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
