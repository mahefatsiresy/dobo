import 'package:dobo/db/database.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _pageTest(
  String description,
  String path,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  Size size = const Size(360, 1200),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await seedDemoAdmin(db, await seedDemoFarm(db));
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

  _pageTest('sync: a refused record is a danger band and a row', '/more/sync', (
    tester,
    db,
  ) async {
    final band = find.ancestor(
      of: find.text('Refusés : 1'),
      matching: find.byType(AttentionBand),
    );
    expect(band, findsOneWidget);
    expect(tester.widget<AttentionBand>(band).severity, BandSeverity.danger);
    expect(
      find.text('Votre rôle ne permet pas cet enregistrement'),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(band).dy,
      lessThan(tester.getTopLeft(find.text('Jamais synchronisé')).dy),
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Réessayer les refusés'),
      findsOneWidget,
    );
  });

  _pageTest('sync: Synchroniser pinned; backup folded', '/more/sync', (
    tester,
    db,
  ) async {
    expect(
      find.descendant(
        of: find.byType(SafeArea),
        matching: find.widgetWithText(FilledButton, 'Synchroniser'),
      ),
      findsOneWidget,
    );
    expect(find.text('Exporter une sauvegarde'), findsNothing);
    await tapAndSettle(tester, find.text('Sauvegarde'));
    expect(find.text('Exporter une sauvegarde'), findsOneWidget);
  });

  _pageTest(
    'account: the role line, the language, sign out last',
    '/more/account',
    (tester, db) async {
      expect(find.textContaining('Membre'), findsWidgets);
      expect(find.text('Français'), findsOneWidget);
    },
  );

  for (final path in ['/more/sync', '/more/account']) {
    _pageTest('$path: large Malagasy text does not overflow', path, (
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
    });
  }

  for (final (name, path) in [
    ('sync_fr', '/more/sync'),
    ('account_fr', '/more/account'),
  ]) {
    _pageTest('$name golden', path, (tester, db) async {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    }, size: const Size(360, 780));
  }
}
