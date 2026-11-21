import 'package:dobo/db/database.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/pond_choice.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _paperTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db, DemoFarm farm)
  body, {
  Size size = const Size(360, 1000),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final farm = await seedDemoFarm(db);
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go('/more/paper');
  await tester.pumpAndSettle();
  await body(tester, db, farm);
});

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _paperTest('all ponds picked; the line counts the pages', (
    tester,
    db,
    farm,
  ) async {
    expect(find.byType(PondChoice), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.text('8 pages : 8 étangs × 1 semaine'), findsOneWidget);
    await tapAndSettle(tester, find.text('2'));
    expect(find.text('16 pages : 8 étangs × 2 semaines'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(ValueKey('pond-${farm['E2']}')));
    expect(find.text('14 pages : 7 étangs × 2 semaines'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SafeArea),
        matching: find.widgetWithText(FilledButton, 'Imprimer'),
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Partager le PDF'),
      findsOneWidget,
    );
  });

  _paperTest('large Malagasy text does not overflow', (tester, db, farm) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  _paperTest('paper golden', (tester, db, farm) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/paper_fr.png'),
    );
  }, size: const Size(360, 780));
}
