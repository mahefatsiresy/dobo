import 'package:dobo/db/database.dart';
import 'package:dobo/features/common/estimated.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:dobo/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _moreTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  bool isAdmin = true,
  bool isSales = true,
  bool trade = true,
}) => appTest(
  description,
  isAdmin: isAdmin,
  isSales: isSales,
  overrides: [_clock],
  (tester, db) async {
    tester.view.physicalSize = const Size(720, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    if (trade) await seedDemoTrade(db, await seedDemoFarm(db));
    await tester.pumpAndSettle();
    appContainer(tester).read(routerProvider).go('/more');
    await tester.pumpAndSettle();
    await body(tester, db);
  },
);

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ListTile));

Finder _inRow(String title, Finder f) =>
    find.descendant(of: _row(title), matching: f);

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _moreTest('groups by job, the farm first', (tester, db) async {
    final headings = [
      for (final k in ['farm', 'sheets', 'phone', 'admin'])
        tester.getTopLeft(find.byKey(ValueKey('more-group-$k'))).dy,
    ];
    expect(headings, [...headings]..sort());
    expect(
      tester.getTopLeft(_row('Lots')).dy,
      lessThan(tester.getTopLeft(_row('Compte')).dy),
    );
    expect(find.text('La ferme'), findsOneWidget);
    expect(find.text('Ce téléphone'), findsOneWidget);
  });

  _moreTest('Lots counts the batches still open', (tester, db) async {
    expect(_inRow('Lots', find.text('6 en cours')), findsOneWidget);
  });

  _moreTest('Aliment shows the days left and the kilos', (tester, db) async {
    final label = _inRow('Aliment', find.byType(EstimatedLabel));
    expect(label, findsOneWidget);
    expect(tester.widget<EstimatedLabel>(label).value, contains('jours'));
    expect(_inRow('Aliment', find.textContaining('kg')), findsOneWidget);
  });

  _moreTest('Synchronisation: never, then what waits', (tester, db) async {
    expect(
      _inRow('Synchronisation', find.text('Jamais synchronisé')),
      findsOneWidget,
    );
    await db
        .into(db.localMeta)
        .insertOnConflictUpdate(
          LocalMetaCompanion.insert(
            key: SyncEngine.lastSyncKey,
            value: demoNow.toIso8601String(),
          ),
        );
    await tester.pumpAndSettle();
    expect(
      _inRow('Synchronisation', find.textContaining('en attente')),
      findsOneWidget,
    );
  });

  _moreTest('Langue shows the language in use', (tester, db) async {
    expect(_inRow('Langue', find.text('Français')), findsOneWidget);
  });

  _moreTest(
    'a member without flags sees neither Administration nor Ventes',
    (tester, db) async {
      expect(find.text('Ventes'), findsNothing);
      expect(find.text('Administration'), findsNothing);
      expect(find.text('Personnes'), findsNothing);
    },
    isAdmin: false,
    isSales: false,
    trade: false,
  );

  _moreTest('large Malagasy text does not overflow', (tester, db) async {
    tester.view.physicalSize = const Size(720, 4000);
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['fr', 'mg']) {
    _moreTest('More golden ($locale)', (tester, db) async {
      tester.view.physicalSize = const Size(720, 1560);
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/more_$locale.png'),
      );
    });
  }
}
