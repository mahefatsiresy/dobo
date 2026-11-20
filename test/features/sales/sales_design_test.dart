import 'package:dobo/db/database.dart';
import 'package:dobo/features/batches/batch_detail_screen.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/sales/customers_screen.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _salesTest(
  String description,
  String path,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  Size size = const Size(360, 1600),
}) => appTest(description, isSales: true, overrides: [_clock], (
  tester,
  db,
) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await seedDemoTrade(db, await seedDemoFarm(db));
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go(path);
  await tester.pumpAndSettle();
  await body(tester, db);
});

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _salesTest(
    'Clients first, then harvests by batch, newest first',
    '/more/sales',
    (tester, db) async {
      final clients = find.byKey(const ValueKey('sales-clients'));
      expect(
        find.descendant(of: clients, matching: find.text('2 clients')),
        findsOneWidget,
      );
      final e6 = tester.getTopLeft(
        find.byKey(const ValueKey('sales-batch-L-E6')),
      );
      final e7 = tester.getTopLeft(
        find.byKey(const ValueKey('sales-batch-L-E7')),
      );
      expect(tester.getTopLeft(clients).dy, lessThan(e6.dy));
      expect(e6.dy, lessThan(e7.dy));
      expect(find.text('Reste à vendre : 5 kg'), findsOneWidget);
      expect(find.text('Reste à vendre : 210 kg'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      await tapAndSettle(
        tester,
        find.byKey(const ValueKey('sales-batch-L-E6')),
      );
      expect(find.byType(BatchDetailScreen), findsOneWidget);
    },
  );

  _salesTest(
    'customers in name order, a last row to add one',
    '/more/sales/customers',
    (tester, db) async {
      expect(
        tester.getTopLeft(find.text('Marché Anosy')).dy,
        lessThan(tester.getTopLeft(find.text('Restaurant Lova')).dy),
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      await tapAndSettle(tester, find.text('Nouveau client'));
      expect(find.byType(CustomerFormScreen), findsOneWidget);
    },
  );

  for (final path in ['/more/sales', '/more/sales/customers']) {
    _salesTest('$path: large Malagasy text does not overflow', path, (
      tester,
      db,
    ) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }, size: const Size(360, 2400));
  }

  for (final (name, path) in [
    ('sales_fr', '/more/sales'),
    ('customers_fr', '/more/sales/customers'),
  ]) {
    _salesTest('$name golden', path, (tester, db) async {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    }, size: const Size(360, 780));
  }
}
