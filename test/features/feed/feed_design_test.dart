import 'package:dobo/db/database.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/estimated.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/feed/feed_delivery_screen.dart';
import 'package:dobo/features/feed/feed_discard_screen.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _feedTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  bool seed = true,
  Size size = const Size(360, 1600),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  if (seed) await seedDemoTrade(db, await seedDemoFarm(db));
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go('/more/feed');
  await tester.pumpAndSettle();
  await body(tester, db);
});

Finder get _pinned => find.descendant(
  of: find.byType(SafeArea),
  matching: find.widgetWithText(FilledButton, 'Livraison'),
);

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _feedTest('the total on hand, loud, with days left', (tester, db) async {
    expect(find.text('En stock'), findsOneWidget);
    final days = find.byType(EstimatedLabel);
    expect(days, findsOneWidget);
    expect(tester.widget<EstimatedLabel>(days).value, contains('jours'));
    final total = find.byKey(const ValueKey('feed-total'));
    expect(
      tester.widget<Text>(total).style?.fontSize,
      Theme.of(tester.element(total)).textTheme.headlineSmall?.fontSize,
    );
  });

  _feedTest('expired feed is a danger band opening its discard', (
    tester,
    db,
  ) async {
    // The logs drew from the oldest lot first, expired or not.
    final band = find.ancestor(
      of: find.textContaining('périmés, à jeter'),
      matching: find.byType(AttentionBand),
    );
    expect(band, findsOneWidget);
    expect(tester.widget<AttentionBand>(band).severity, BandSeverity.danger);
    await tapAndSettle(tester, band);
    expect(find.byType(FeedDiscardScreen), findsOneWidget);
    expect(find.textContaining('Lot C'), findsOneWidget);
  });

  _feedTest('lots grouped by phase, oldest first', (tester, db) async {
    final fry = tester.getTopLeft(find.text('Alevinage')).dy;
    final grow = tester.getTopLeft(find.text('Grossissement')).dy;
    expect(fry, lessThan(grow));
    expect(
      tester.getTopLeft(find.textContaining('Lot A')).dy,
      lessThan(tester.getTopLeft(find.textContaining('Lot B')).dy),
    );
    expect(find.text('À utiliser en priorité'), findsOneWidget);
  });

  _feedTest('a lot opens its delivery; Livraison is pinned', (
    tester,
    db,
  ) async {
    expect(find.byType(Card), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(_pinned, findsOneWidget);
    await tapAndSettle(tester, find.textContaining('Lot B'));
    expect(find.byType(FeedDeliveryScreen), findsOneWidget);
    expect(find.text('Jeter une partie'), findsOneWidget);
  });

  _feedTest('no feed yet: say what to do', (tester, db) async {
    expect(
      find.text('Aucun aliment en stock. Enregistrez une livraison.'),
      findsOneWidget,
    );
    expect(_pinned, findsOneWidget);
  }, seed: false);

  _feedTest('large Malagasy text does not overflow', (tester, db) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, size: const Size(360, 2400));

  for (final locale in ['fr', 'mg']) {
    _feedTest('feed golden ($locale)', (tester, db) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/feed_$locale.png'),
      );
    }, size: const Size(360, 780));
  }
}
