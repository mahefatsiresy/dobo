import 'package:dobo/db/database.dart';
import 'package:dobo/features/batches/stock_screen.dart';
import 'package:dobo/features/common/pond_choice.dart';
import 'package:dobo/features/common/coded_band.dart';
import 'package:dobo/features/common/estimated.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/pond_colour.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _listTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db, DemoFarm farm)
  body, {
  bool seed = true,
  Size size = const Size(360, 1400),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final farm = <String, String>{};
  if (seed) {
    farm.addAll(await seedDemoFarm(db));
    await seedDemoTrade(db, farm);
  }
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go('/more/batches');
  await tester.pumpAndSettle();
  await body(tester, db, farm);
});

String _path(WidgetTester tester) =>
    appContainer(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();

Finder _rowOf(String code) => find.byKey(ValueKey('batch-row-$code'));

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _listTest('open batches in code order; closed ones folded', (
    tester,
    db,
    farm,
  ) async {
    final tops = [
      for (final c in ['L-E1', 'L-E2', 'L-E3', 'L-E4', 'L-E5', 'L-E6'])
        tester.getTopLeft(_rowOf(c)).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(_rowOf('L-E7'), findsNothing);
    expect(find.text('Lots terminés'), findsOneWidget);
    expect(find.text('1 lot'), findsOneWidget);
  });

  _listTest('a row: the ponds as codes, ≈ before the count', (
    tester,
    db,
    farm,
  ) async {
    final row = _rowOf('L-E1');
    expect(
      find.descendant(of: row, matching: find.byType(PondCode)),
      findsNWidgets(2),
    );
    final count = find.descendant(
      of: row,
      matching: find.byType(EstimatedLabel),
    );
    expect(count, findsWidgets);
    expect(find.byType(Card), findsNothing);
  });

  _listTest('the isolated band opens E4; a row opens its batch', (
    tester,
    db,
    farm,
  ) async {
    final band = find.descendant(
      of: _rowOf('L-E4'),
      matching: find.byType(CodedBand),
    );
    expect(band, findsOneWidget);
    await tapAndSettle(tester, band);
    expect(_path(tester), '/ponds/${farm['E4']}');
    appContainer(tester).read(routerProvider).go('/more/batches');
    await tester.pumpAndSettle();
    await tapAndSettle(
      tester,
      find.descendant(of: _rowOf('L-E2'), matching: find.text('L-E2')),
    );
    expect(_path(tester), startsWith('/more/batches/'));
  });

  _listTest('the last row stocks a pond', (tester, db, farm) async {
    await tapAndSettle(tester, find.text('Empoissonner un étang'));
    expect(find.byType(StockScreen), findsOneWidget);
    expect(find.byType(PondChoice), findsOneWidget);
  });

  _listTest('no batches yet: say what to do', (tester, db, farm) async {
    expect(
      find.text(
        'Aucun lot. Empoissonnez un étang depuis sa page ou ci-dessous.',
      ),
      findsOneWidget,
    );
    expect(find.text('Empoissonner un étang'), findsOneWidget);
  }, seed: false);

  _listTest('large Malagasy text does not overflow', (tester, db, farm) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, size: const Size(360, 2400));

  for (final locale in ['fr', 'mg']) {
    _listTest('batches golden ($locale)', (tester, db, farm) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/batches_$locale.png'),
      );
    }, size: const Size(360, 780));
  }
}
