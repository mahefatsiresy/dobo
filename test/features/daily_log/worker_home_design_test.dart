import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/pictograms.dart';
import 'package:dobo/features/daily_log/stop_feeding_sign.dart';
import 'package:dobo/features/ponds/pond_overview.dart';
import 'package:dobo/l10n/formatting.dart';
import 'package:dobo/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

Finder _tile(String code) => find.byKey(ValueKey('tile-$code'));

void _homeTest(
  String description,
  Future<void> Function(WidgetTester tester, DemoFarm farm) body, {
  Future<void> Function(AppDatabase db, DemoFarm farm)? before,
}) => appTest(
  description,
  role: MemberRole.worker,
  isAdmin: false,
  overrides: [clockProvider.overrideWithValue(() => demoNow)],
  (tester, db) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final farm = await seedDemoFarm(db);
    await before?.call(db, farm);
    await tester.pumpAndSettle();
    await body(tester, farm);
  },
);

void main() {
  setUpAll(loadAppFonts);

  _homeTest('only ponds with fish, in code order', (tester, farm) async {
    final codes = ['E1', 'E2', 'E3', 'E4', 'E5', 'E6'];
    for (final c in codes) {
      await tester.ensureVisible(_tile(c));
      expect(_tile(c), findsOneWidget, reason: c);
    }
    expect(_tile('P1'), findsNothing);
    expect(_tile('P2'), findsNothing);
    await tester.ensureVisible(_tile('E1'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(_tile('E1')).dy,
      lessThan(tester.getTopLeft(_tile('E3')).dy),
    );
  });

  _homeTest("the day's progress", (tester, farm) async {
    expect(find.text('1 / 6 vita'), findsOneWidget);
  });

  _homeTest(
    'every pond done: one line says so',
    before: (db, farm) async {
      final session = (await SetupRepository(db).currentSession())!;
      for (final c in ['E2', 'E3', 'E4', 'E5', 'E6']) {
        await DailyLogRepository(db, session).save(
          DailyLogInput(
            pondId: farm[c]!,
            date: DateTime(2026, 3, 15),
            feedGivenG: 1000,
          ),
        );
      }
    },
    (tester, farm) async {
      expect(find.text('Vita daholo ny dobo'), findsOneWidget);
      expect(find.textContaining(' / '), findsNothing);
    },
  );

  _homeTest('the ration to aim for: feed bowl and plain kg', (
    tester,
    farm,
  ) async {
    final ration = appContainer(tester)
        .read(pondOverviewsProvider)
        .value!
        .singleWhere((o) => o.pond.code == 'E3')
        .rationG;
    expect(
      find.descendant(of: _tile('E3'), matching: find.byIcon(feedIcon)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _tile('E3'),
        matching: find.text(formatKg(ration, const Locale('fr'))),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('≈'), findsNothing);
    expect(
      find.descendant(of: _tile('E2'), matching: find.byType(StopFeedingSign)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _tile('E2'), matching: find.byIcon(feedIcon)),
      findsNothing,
    );
  });

  _homeTest('at 130 % text the ration still fits its tile', (
    tester,
    farm,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  appTest(
    'no pond holds fish: the home says so',
    role: MemberRole.worker,
    isAdmin: false,
    (tester, db) async {
      final session = (await SetupRepository(db).currentSession())!;
      await PondRepository(db, session).create(
        const PondInput(
          code: 'E1',
          colour: PondColour.blue,
          role: PondRole.growout,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tsy misy dobo misy trondro'), findsOneWidget);
    },
  );

  for (final locale in ['mg', 'fr']) {
    _homeTest('worker home golden $locale', (tester, farm) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold).last,
        matchesGoldenFile('goldens/home_$locale.png'),
      );
    });
  }
}
