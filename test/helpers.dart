import 'package:dobo/app.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fresh in-memory database, closed when the test ends.
AppDatabase testDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// Pumps the whole app on [db] and waits for it to settle.
Future<void> pumpApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const DoboApp(),
  ));
  await tester.pumpAndSettle();
}

/// The provider container of the running app.
ProviderContainer appContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DoboApp)));

