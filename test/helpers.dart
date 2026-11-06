import 'package:dobo/app.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
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
  MemberRole role = MemberRole.member,
  bool isAdmin = true,
  List<Override> overrides = const [],
}) {
  testWidgets(description, (tester) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    if (setUp) {
      await SetupRepository(
        db,
      ).completeSetup(siteName: 'Ambohidratrimo', role: role, isAdmin: isAdmin);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...overrides],
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

/// Scrolls [finder] into view, down or up, even in a lazily built list.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  for (final delta in const [200.0, -200.0]) {
    if (finder.evaluate().isNotEmpty) break;
    try {
      await tester.scrollUntilVisible(
        finder,
        delta,
        scrollable: _verticalScrollable,
        maxScrolls: 30,
      );
    } on StateError {
      // Not that way; try the other.
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view, whichever way it is, and waits.
Future<void> reveal(WidgetTester tester, Finder finder) =>
    _reveal(tester, finder);

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
  // Done typing: on a device the keyboard and selection handles would
  // otherwise cover what comes next.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

/// The innermost vertical list on screen. Text fields have their own
/// scrollables (restoration id "editable"), sideways or, when multi-line,
/// vertical: they are skipped.
final _verticalScrollable = find
    .byWidgetPredicate(
      (w) =>
          w is Scrollable &&
          w.restorationId != 'editable' &&
          axisDirectionToAxis(w.axisDirection) == Axis.vertical,
    )
    .last;

/// Taps [button] in a dialog while the keyboard is up, then lets the
/// keyboard close during the dialog's exit animation, as on a phone: the
/// closing dialog is rebuilt with the new insets.
Future<void> tapAsKeyboardCloses(WidgetTester tester, Finder button) async {
  tester.view.viewInsets = const FakeViewPadding(bottom: 250);
  addTearDown(tester.view.resetViewInsets);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  tester.view.resetViewInsets();
  await tester.pumpAndSettle();
}
