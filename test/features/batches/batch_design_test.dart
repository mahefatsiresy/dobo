import 'package:dobo/db/database.dart';
import 'package:dobo/features/batches/stock_screen.dart';
import 'package:dobo/features/batches/transfer_screen.dart';
import 'package:dobo/features/common/coded_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/sales/harvest_screen.dart';
import 'package:dobo/features/sales/sale_screen.dart';
import 'package:dobo/l10n/formatting.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _batchTest(
  String description,
  String code,
  Future<void> Function(WidgetTester tester, AppDatabase db, DemoFarm farm)
  body, {
  bool isSales = true,
  Size size = const Size(360, 2000),
}) => appTest(description, isSales: isSales, overrides: [_clock], (
  tester,
  db,
) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final farm = await seedDemoFarm(db);
  await seedDemoTrade(db, farm);
  final id = (await (db.select(
    db.batches,
  )..where((b) => b.code.equals(code))).getSingle()).id;
  farm['batch'] = id;
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go('/more/batches/$id');
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

Finder get _pinned => find.descendant(
  of: find.byType(SafeArea),
  matching: find.byType(FilledButton),
);

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _batchTest('L-E1: its ponds open the pond page', 'L-E1', (
    tester,
    db,
    farm,
  ) async {
    final e1 = find.byKey(ValueKey('place-${farm['E1']}'));
    expect(e1, findsOneWidget);
    expect(find.byKey(ValueKey('place-${farm['P2']}')), findsOneWidget);
    expect(
      find.descendant(of: e1, matching: find.byIcon(Icons.chevron_right)),
      findsOneWidget,
    );
    expect(find.textContaining('Survie'), findsOneWidget);
    await tapAndSettle(tester, e1);
    expect(_path(tester), '/ponds/${farm['E1']}');
  });

  _batchTest('L-E1: history rows open their correction', 'L-E1', (
    tester,
    db,
    farm,
  ) async {
    final move = find.byKey(const ValueKey('transfer-ponds'));
    expect(
      find.descendant(of: move, matching: find.text('E1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: move, matching: find.text('P2')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.swap_horiz), findsWidgets);
    await tapAndSettle(tester, move);
    expect(find.byType(TransferScreen), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton));
    await tapAndSettle(
      tester,
      find.byKey(
        ValueKey(
          'event-${(await db.select(db.stockings).get()).firstWhere((s) => s.batchId == farm['batch']).id}',
        ),
      ),
    );
    expect(find.byType(StockScreen), findsOneWidget);
  });

  _batchTest('L-E1: origin folded; no cards, no Corriger', 'L-E1', (
    tester,
    db,
    farm,
  ) async {
    expect(find.text('Origine'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.text('Corriger'), findsNothing);
  });

  _batchTest('L-E4: the isolated band at the top opens E4', 'L-E4', (
    tester,
    db,
    farm,
  ) async {
    final band = find.byType(CodedBand);
    expect(band, findsWidgets);
    expect(
      find.descendant(of: band.first, matching: find.text('Étang isolé')),
      findsOneWidget,
    );
    await tapAndSettle(tester, band.first);
    expect(_path(tester), '/ponds/${farm['E4']}');
  });

  _batchTest('L-E6: what is left to sell, Vendre, Récolter pinned', 'L-E6', (
    tester,
    db,
    farm,
  ) async {
    expect(
      find.text('Reste à vendre : ${formatKg(5000, const Locale('fr'))}'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Récolter'), findsOneWidget);
    expect(_pinned, findsOneWidget);
    await tapAndSettle(tester, find.widgetWithText(OutlinedButton, 'Vendre'));
    expect(find.byType(SaleScreen), findsOneWidget);
    expect(find.textContaining('reste 5 kg'), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton));
    await tapAndSettle(tester, find.textContaining('Marché Anosy'));
    expect(find.byType(SaleScreen), findsOneWidget);
    expect(find.text('Enregistrer la correction'), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton));
    await tapAndSettle(tester, find.textContaining('Partielle'));
    expect(find.byType(HarvestScreen), findsOneWidget);
  });

  _batchTest('without the sales flag: rows only to read', 'L-E6', (
    tester,
    db,
    farm,
  ) async {
    expect(_pinned, findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Vendre'), findsNothing);
    await tester.tap(find.textContaining('Partielle'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(HarvestScreen), findsNothing);
  }, isSales: false);

  _batchTest('L-E7 closed: the cycle, the trace sheet pinned', 'L-E7', (
    tester,
    db,
    farm,
  ) async {
    expect(
      find.text(
        'Récolté ${formatCount(1100, const Locale('fr'))} poissons, '
        '${formatKg(210000, const Locale('fr'))}',
      ),
      findsOneWidget,
    );
    // The demo logs no feed for L-E7: no ratio that would look measured.
    expect(find.textContaining('IC du cycle'), findsNothing);
    expect(find.byKey(ValueKey('place-${farm['E7']}')), findsNothing);
    expect(
      find.widgetWithText(FilledButton, 'Fiche de traçabilité'),
      findsOneWidget,
    );
  });

  _batchTest('⋮ holds edit and the trace sheet', 'L-E1', (
    tester,
    db,
    farm,
  ) async {
    await tapAndSettle(tester, find.byIcon(Icons.more_vert));
    expect(find.text('Modifier le lot'), findsOneWidget);
    expect(find.text('Fiche de traçabilité'), findsOneWidget);
  });

  appTest('the pond page batch line opens the batch', (tester, db) async {
    tester.view.physicalSize = const Size(720, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final farm = await seedDemoFarm(db);
    await tester.pumpAndSettle();
    appContainer(tester).read(routerProvider).go('/ponds/${farm['E1']}');
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.byKey(const ValueKey('batch-link-L-E1')));
    expect(_path(tester), startsWith('/more/batches/'));
  }, overrides: [_clock]);

  _batchTest('large Malagasy text does not overflow', 'L-E6', (
    tester,
    db,
    farm,
  ) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, size: const Size(360, 3000));

  for (final (name, code, locale, scrolled) in [
    ('batch_fr', 'L-E1', 'fr', false),
    ('batch_fr_bottom', 'L-E1', 'fr', true),
    ('batch_mg', 'L-E6', 'mg', false),
    ('batch_closed_fr', 'L-E7', 'fr', false),
  ]) {
    _batchTest('$name golden', code, (tester, db, farm) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      if (scrolled) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    }, size: const Size(360, 780));
  }
}
