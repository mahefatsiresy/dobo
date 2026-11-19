import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/feed_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/alerts/alert_providers.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/pond_colour.dart';
import 'package:dobo/features/feed/feed_stock_screen.dart';
import 'package:dobo/features/ponds/pond_detail_screen.dart';
import 'package:dobo/features/readings/sample_screen.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

/// An Alerts-tab test on the demo farm (unless [seed] is false), the clock
/// at [demoNow], a tall phone, the tab open.
void _alertsTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  Size size = const Size(360, 2400),
  bool seed = true,
  Future<void> Function(AppDatabase db)? before,
}) => appTest(
  description,
  overrides: [clockProvider.overrideWithValue(() => demoNow)],
  (tester, db) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    if (seed) await seedDemoFarm(db);
    await before?.call(db);
    await tester.pumpAndSettle();
    appContainer(tester).read(routerProvider).go('/alerts');
    await tester.pumpAndSettle();
    await body(tester, db);
  },
);

List<AttentionBand> _bands(WidgetTester tester) =>
    tester.widgetList<AttentionBand>(find.byType(AttentionBand)).toList();

String? _code(WidgetTester tester, AttentionBand band) {
  final code = find.descendant(
    of: find.byWidget(band),
    matching: find.byType(PondCode),
  );
  return code.evaluate().isEmpty ? null : tester.widget<PondCode>(code).code;
}

void main() {
  setUpAll(loadAppFonts);

  _alertsTest('danger first, then to do, each in pond code order', (
    tester,
    db,
  ) async {
    final bands = _bands(tester);
    final danger = [
      for (final b in bands)
        if (b.severity == BandSeverity.danger) b,
    ];
    expect(
      [for (final b in danger) _code(tester, b)],
      ['E2', 'E4', 'E5', 'E5'],
    );
    expect(danger[0].text, startsWith('Oxygène'));
    expect(danger[1].text, 'Étang isolé');
    expect(danger[2].text, 'À vérifier');
    // Every danger band comes before every to-do band.
    final firstTodo = bands.indexWhere(
      (b) => b.severity == BandSeverity.warning,
    );
    expect(firstTodo, danger.length);
    final todoCodes = [for (final b in bands.skip(firstTodo)) _code(tester, b)];
    expect(todoCodes, [...todoCodes]..sort());
    expect(
      tester.getTopLeft(find.textContaining('Danger')).dy,
      lessThan(tester.getTopLeft(find.byWidget(danger.first)).dy),
    );
    expect(
      tester.getTopLeft(find.textContaining('À faire')).dy,
      lessThan(tester.getTopLeft(find.byWidget(bands[firstTodo])).dy),
    );
  });

  _alertsTest('each band stands apart from the next', (tester, db) async {
    final rects = [
      for (final b in _bands(tester)) tester.getRect(find.byWidget(b)),
    ];
    for (var i = 1; i < rects.length; i++) {
      expect(rects[i].top - rects[i - 1].bottom, greaterThanOrEqualTo(2));
    }
  });

  _alertsTest('the Danger heading counts as the badge does', (
    tester,
    db,
  ) async {
    final d = appContainer(tester).read(dangerPondsProvider);
    expect(find.text('Danger ${d.ponds + d.farmWide}'), findsOneWidget);
  });

  _alertsTest('each band opens its fix', (tester, db) async {
    await tapAndSettle(tester, find.text('Étang isolé'));
    expect(find.byType(PondDetailScreen), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton));
    await tapAndSettle(tester, find.textContaining('L-E2 : échantillonnage'));
    expect(find.byType(SampleScreen), findsOneWidget);
  });

  _alertsTest('bands carry the pond code; no colour squares, no chips', (
    tester,
    db,
  ) async {
    for (final b in _bands(tester)) {
      expect(_code(tester, b), isNotNull, reason: b.text);
    }
    expect(find.byType(PondTag), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  _alertsTest(
    'old feed is a farm-wide danger, last, with no pond, opening the feed',
    before: (db) async {
      final session = (await SetupRepository(db).currentSession())!;
      await FeedRepository(db, session).deliver(
        FeedDeliveryInput(
          date: DateTime(2025, 11, 1),
          phase: Phase.growout,
          weightG: 25000,
          manufacturedOn: DateTime(2025, 11, 1),
        ),
      );
    },
    (tester, db) async {
      final danger = [
        for (final b in _bands(tester))
          if (b.severity == BandSeverity.danger) b,
      ];
      expect(_code(tester, danger.last), isNull);
      await tapAndSettle(tester, find.byWidget(danger.last));
      expect(find.byType(FeedStockScreen), findsOneWidget);
    },
  );

  _alertsTest('nothing open: a tick says so', seed: false, (tester, db) async {
    expect(find.byIcon(Icons.task_alt), findsOneWidget);
    expect(find.text('Aucune alerte, rien à faire'), findsOneWidget);
    expect(find.textContaining('Danger'), findsNothing);
  });

  appTest(
    'while alerts load: a spinner, not "nothing open"',
    overrides: [
      clockProvider.overrideWithValue(() => demoNow),
      alertsProvider.overrideWithValue(const AsyncLoading()),
    ],
    settle: false,
    (tester, db) async {
      appContainer(tester).read(routerProvider).go('/alerts');
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Aucune alerte, rien à faire'), findsNothing);
    },
  );

  _alertsTest(
    'large text in Malagasy: nothing overflows',
    size: const Size(320, 3200),
    (tester, db) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in ['fr', 'mg']) {
    _alertsTest('alerts golden $locale', size: const Size(360, 780), (
      tester,
      db,
    ) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold).last,
        matchesGoldenFile('goldens/alerts_$locale.png'),
      );
    });
  }
}
