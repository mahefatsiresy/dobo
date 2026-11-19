import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/alerts/alert_providers.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/mini_chart.dart';
import 'package:dobo/features/ponds/pond_row.dart';
import 'package:dobo/features/readings/sample_screen.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:dobo/theme/dobo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

/// A pond-page test on the demo farm: clock at [demoNow], a tall phone,
/// the farm seeded, then the page of [code] opened.
void _pondTest(
  String description,
  String code,
  Future<void> Function(WidgetTester tester, DemoFarm farm) body, {
  bool isAdmin = true,
  Size size = const Size(360, 2400),
  Future<void> Function(AppDatabase db, DemoFarm farm)? before,
}) => appTest(
  description,
  isAdmin: isAdmin,
  overrides: [clockProvider.overrideWithValue(() => demoNow)],
  (tester, db) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final farm = await seedDemoFarm(db);
    await before?.call(db, farm);
    await tester.pumpAndSettle();
    await _open(tester, farm, code);
    await body(tester, farm);
  },
);

Future<void> _open(WidgetTester tester, DemoFarm farm, String code) async {
  appContainer(tester).read(routerProvider).go('/ponds/${farm[code]}');
  await tester.pumpAndSettle();
}

Finder get _bar => find.descendant(
  of: find.byType(SafeArea),
  matching: find.byType(FilledButton),
);

String _barLabel(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: _bar, matching: find.byType(Text)))
    .data!;

List<AttentionBand> _bands(WidgetTester tester) =>
    tester.widgetList<AttentionBand>(find.byType(AttentionBand)).toList();

void main() {
  setUpAll(loadAppFonts);

  _pondTest('E2: every item is its own band, each opening its fix', 'E2', (
    tester,
    farm,
  ) async {
    final bands = _bands(tester);
    expect(bands, hasLength(2));
    expect(bands[0].severity, BandSeverity.danger);
    expect(bands[0].text, startsWith('Oxygène'));
    expect(bands[1].severity, BandSeverity.warning);
    expect(bands[1].text, contains('échantillonnage'));
    expect(bands.any((b) => b.text.contains(', et ')), isFalse);
    await tapAndSettle(tester, find.text(bands[1].text));
    expect(find.byType(SampleScreen), findsOneWidget);
  });

  _pondTest('E2 today: stop feeding, no ration, not logged', 'E2', (
    tester,
    farm,
  ) async {
    expect(find.text('Ne pas nourrir'), findsOneWidget);
    expect(find.byKey(rationKey), findsNothing);
    expect(find.text('Pas encore de journal'), findsOneWidget);
  });

  _pondTest('E1 today: the ration, logged, what was given', 'E1', (
    tester,
    farm,
  ) async {
    final ration = tester.widget<Text>(
      find.descendant(of: find.byKey(rationKey), matching: find.byType(Text)),
    );
    expect(
      ration.style!.fontSize,
      doboTheme().textTheme.headlineSmall!.fontSize,
    );
    expect(find.text('Journal fait'), findsOneWidget);
    expect(find.text('Donné : 7,4 kg'), findsOneWidget);
  });

  _pondTest('a pond with fish: the daily log is the pinned bar only', 'E1', (
    tester,
    farm,
  ) async {
    expect(_barLabel(tester), 'Journal du jour');
    expect(find.text('Journal du jour'), findsOneWidget);
  });

  _pondTest('an empty pond: prepare it, never log a day', 'P1', (
    tester,
    farm,
  ) async {
    expect(_barLabel(tester), "Préparer l'étang");
    expect(find.text('Journal du jour'), findsNothing);
    expect(find.text('Préparation'), findsNothing);
    expect(find.text('Empoissonner'), findsOneWidget);
  });

  _pondTest(
    'a ready pond: stock it from the bar',
    'P2',
    before: (db, farm) async {
      final session = (await SetupRepository(db).currentSession())!;
      await PondRepository(
        db,
        session,
      ).setStatus(farm['P2']!, PondStatus.ready);
    },
    (tester, farm) async {
      expect(_barLabel(tester), 'Empoissonner');
      expect(find.text('Empoissonner'), findsOneWidget);
    },
  );

  _pondTest('an isolated pond offers release; a healthy one does not', 'E4', (
    tester,
    farm,
  ) async {
    expect(find.text("Lever l'isolement"), findsOneWidget);
    expect(_bands(tester).first.text, 'Étang isolé');
    await _open(tester, farm, 'E1');
    expect(find.text("Lever l'isolement"), findsNothing);
  });

  late String secondBatch;
  _pondTest(
    'two batches in a pond: each weighs its own',
    'E3',
    before: (db, farm) async {
      final session = (await SetupRepository(db).currentSession())!;
      secondBatch = await BatchRepository(db, session).stockBatch(
        StockInput(
          code: 'L-E3b',
          pondId: farm['E3']!,
          date: DateTime(2026, 3, 12),
          count: 300,
          avgWeightMg: 20000,
        ),
      );
    },
    (tester, farm) async {
      final weigh = find.text('Peser');
      expect(weigh, findsNWidgets(2));
      expect(find.text('L-E3b'), findsOneWidget);
      // The weight summary: one line per batch, each named.
      expect(find.text('L-E3 : 90 g\nL-E3b : 20 g'), findsOneWidget);
      await tester.ensureVisible(weigh.last);
      await tapAndSettle(tester, weigh.last);
      final sample = tester.widget<SampleScreen>(find.byType(SampleScreen));
      expect(sample.pondId, farm['E3']);
      expect(sample.batchId, secondBatch);
    },
  );

  appTest(
    'what was given follows a later correction of the day',
    overrides: [clockProvider.overrideWithValue(() => demoNow)],
    (tester, db) async {
      tester.view.physicalSize = const Size(720, 4800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final farm = await seedDemoFarm(db);
      await tester.pumpAndSettle();
      await _open(tester, farm, 'E1');
      expect(find.text('Donné : 7,4 kg'), findsOneWidget);
      // Another phone's log of the same day arrives (sync, transcription).
      final session = (await SetupRepository(db).currentSession())!;
      await DailyLogRepository(db, session).saveWeek([
        DailyLogInput(
          pondId: farm['E1']!,
          date: DateTime(2026, 3, 15),
          feedGivenG: 8000,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Donné : 8 kg'), findsOneWidget);
    },
  );

  _pondTest('archiving an empty pond goes back to the list', 'P2', (
    tester,
    farm,
  ) async {
    await tapAndSettle(tester, find.byTooltip("Plus d'actions"));
    await tapAndSettle(tester, find.text('Archiver'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Archiver'),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('pondRow-E1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pondRow-P2')), findsNothing);
  });

  _pondTest('the ⋮ menu: edit for admins, archive for all', 'E1', (
    tester,
    farm,
  ) async {
    await tapAndSettle(tester, find.byTooltip("Plus d'actions"));
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Archiver'), findsOneWidget);
  });

  _pondTest('members who are not admins: archive only', 'E1', isAdmin: false, (
    tester,
    farm,
  ) async {
    await tapAndSettle(tester, find.byTooltip("Plus d'actions"));
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Archiver'), findsOneWidget);
  });

  _pondTest('charts stay folded until opened', 'E1', (tester, farm) async {
    expect(find.byType(MiniChart), findsNothing);
    expect(find.text('150 g'), findsOneWidget); // the weight summary
    await tester.ensureVisible(find.text('Poids moyen (g)'));
    await tapAndSettle(tester, find.text('Poids moyen (g)'));
    expect(find.byType(MiniChart), findsOneWidget);
  });

  appTest(
    'while alerts load: no band, no ration',
    overrides: [
      clockProvider.overrideWithValue(() => demoNow),
      alertsProvider.overrideWithValue(const AsyncLoading()),
    ],
    settle: false,
    (tester, db) async {
      final farm = await seedDemoFarm(db);
      appContainer(tester).read(routerProvider).go('/ponds/${farm['E2']}');
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byType(AttentionBand), findsNothing);
      expect(find.byKey(rationKey), findsNothing);
    },
  );

  _pondTest(
    'large text in Malagasy: nothing overflows',
    'E4',
    size: const Size(320, 3200),
    (tester, farm) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Lanjaina'), findsOneWidget);
    },
  );

  for (final (code, locale) in [('E2', 'fr'), ('E2', 'mg'), ('P1', 'fr')]) {
    _pondTest(
      'pond page golden $code $locale',
      code,
      size: const Size(360, 780),
      (tester, farm) async {
        appContainer(tester)
            .read(localeControllerProvider.notifier)
            .set(Locale(locale));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).last,
          matchesGoldenFile('goldens/pond_${code}_$locale.png'),
        );
      },
    );
  }
}
