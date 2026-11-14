import 'package:dobo/console/console_app.dart';
import 'package:dobo/console/console_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// The web console, on a desktop-sized window, opened at [at].
Future<ProviderContainer> pumpConsole(
  WidgetTester tester, {
  String at = '/membres',
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const ConsoleApp()),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ConsoleApp)),
  );
  container.read(consoleRouterProvider).go(at);
  await tester.pumpAndSettle();
  return container;
}
