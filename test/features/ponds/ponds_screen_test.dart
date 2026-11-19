import 'package:dobo/domain/stock.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/alerts/alert_providers.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/pond_colour.dart';
import 'package:dobo/features/ponds/pond_detail_screen.dart';
import 'package:dobo/features/ponds/pond_overview.dart';
import 'package:dobo/features/ponds/pond_row.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:dobo/l10n/formatting.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/theme/dobo_theme.dart';
import 'package:dobo/theme/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../fixtures.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

const _fr = Locale('fr');

/// A demo-farm test: the clock at [demoNow], a tall phone so every row is
/// built, the farm seeded and settled.
void _demoTest(
  String description,
  Future<void> Function(WidgetTester tester, DemoFarm farm) body, {
  bool isAdmin = true,
  Size size = const Size(360, 2400),
}) => appTest(
  description,
  isAdmin: isAdmin,
  overrides: [clockProvider.overrideWithValue(() => demoNow)],
  (tester, db) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final farm = await seedDemoFarm(db);
    await tester.pumpAndSettle();
    await body(tester, farm);
  },
);

Finder _row(String code) => find.byKey(ValueKey('pondRow-$code'));
Finder _in(String code, Finder f) =>
    find.descendant(of: _row(code), matching: f);
String _bandText(WidgetTester t, String code) =>
    t.widget<AttentionBand>(_in(code, find.byType(AttentionBand))).text;

void main() {
  setUpAll(loadAppFonts);

  appTest('empty farm invites to add a pond', (tester, db) async {
    expect(find.text('Aucun étang : ajoutez le premier'), findsOneWidget);
    expect(find.text('Ajouter un étang'), findsOneWidget);
  });

  appTest(
    'while alerts load: no all-clear, no ration, no total',
    overrides: [alertsProvider.overrideWithValue(const AsyncLoading())],
    settle: false,
    (tester, db) async {
      await seedDemoFarm(db);
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('en danger'), findsNothing);
      expect(find.byKey(rationKey), findsNothing);
      expect(find.textContaining('tous les étangs'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  _demoTest('rows come in code order', (tester, farm) async {
    final codes = ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'P1', 'P2'];
    final tops = [for (final c in codes) tester.getTopLeft(_row(c)).dy];
    expect(tops, [...tops]..sort());
  });

  _demoTest('rows show the pond code in ink with a swatch, not a strip', (
    tester,
    farm,
  ) async {
    expect(_in('E4', find.byType(PondCode)), findsOneWidget);
    // The only large colour on a row is its band: no full-height paint.
    final filled = find.descendant(
      of: _row('E4'),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color ==
                pondColourValue(PondColour.red),
      ),
    );
    expect(filled, findsOneWidget);
    expect(tester.getSize(filled).width, 12);
  });

  _demoTest('a healthy pond: figures, ration first, logged, no band', (
    tester,
    farm,
  ) async {
    expect(_in('E1', find.byType(AttentionBand)), findsNothing);
    expect(_in('E1', find.text('≈ 1 240 poissons')), findsOneWidget);
    expect(_in('E1', find.text('≈\u00a0186 kg, 150 g')), findsOneWidget);
    expect(_in('E1', find.text('Grossissement')), findsOneWidget);
    expect(_in('E1', find.text('Journal fait')), findsOneWidget);
    final ration = tester.widget<Text>(
      find.descendant(
        of: _in('E1', find.byKey(rationKey)),
        matching: find.byType(Text),
      ),
    );
    expect(ration.data, startsWith('≈ '));
    expect(ration.data, endsWith(' kg'));
    final theme = doboTheme().textTheme.headlineSmall!;
    expect(ration.style!.fontSize, theme.fontSize);
  });

  _demoTest('bands: the most urgent item and how many more', (
    tester,
    farm,
  ) async {
    final e2 = tester.widget<AttentionBand>(
      _in('E2', find.byType(AttentionBand)),
    );
    expect(e2.severity, BandSeverity.danger);
    expect(e2.text, startsWith('Oxygène'));
    expect(e2.text, endsWith(', et 1 autre'));
    expect(_bandText(tester, 'E3'), isNot(contains(', et')));
    expect(
      tester
          .widget<AttentionBand>(_in('E3', find.byType(AttentionBand)))
          .severity,
      BandSeverity.warning,
    );
    expect(_bandText(tester, 'E4'), startsWith('Étang isolé'));
    expect(_bandText(tester, 'E5'), startsWith('À vérifier'));
    expect(_in('E1', find.text('Pas encore de journal')), findsNothing);
    expect(_in('E3', find.text('Pas encore de journal')), findsOneWidget);
  });

  _demoTest('a pond that must not be fed shows the sign, not a ration', (
    tester,
    farm,
  ) async {
    for (final code in ['E2', 'E6']) {
      expect(_in(code, find.text('Ne pas nourrir')), findsOneWidget);
      expect(_in(code, find.byKey(rationKey)), findsNothing);
    }
  });

  _demoTest('the top lines: total ration of fed ponds, danger count', (
    tester,
    farm,
  ) async {
    final container = appContainer(tester);
    final overviews = {
      for (final o in container.read(pondOverviewsProvider).value!)
        o.pond.code: o,
    };
    final fed = ['E1', 'E3', 'E4', 'E5'];
    for (final c in ['E1', 'E2', 'E3', 'E4', 'E5', 'E6']) {
      final stop = container.read(stopFeedingProvider(farm[c]!));
      expect(stop.isEmpty, fed.contains(c), reason: c);
    }
    final total = fed.fold(0, (n, c) => n + overviews[c]!.rationG);
    expect(total, greaterThan(0));
    expect(find.text('Ration du jour, tous les étangs :'), findsOneWidget);
    expect(find.text('≈\u00a0${formatKg(total, _fr)}'), findsOneWidget);
    expect(find.text('3 étangs en danger'), findsOneWidget);
  });

  _demoTest('ponds without fish are one short line', (tester, farm) async {
    expect(
      _in(
        'P1',
        find.text('En préparation : Traitement (chaux vive ou chlore)'),
      ),
      findsOneWidget,
    );
    expect(_in('P2', find.text('Vide')), findsOneWidget);
    expect(
      tester.getSize(_row('P1')).height,
      lessThan(tester.getSize(_row('E1')).height),
    );
  });

  _demoTest('a short row lines its status up with the pond code', (
    tester,
    farm,
  ) async {
    for (final (code, status) in [
      ('P1', 'En préparation : Traitement (chaux vive ou chlore)'),
      ('P2', 'Vide'),
    ]) {
      final codeBox = tester.getRect(_in(code, find.text(code)));
      final statusBox = tester.getRect(_in(code, find.text(status)));
      // First lines share a centre line, within 3 dp.
      final statusFirstLine = statusBox.top + 11;
      expect(
        (codeBox.center.dy - statusFirstLine).abs(),
        lessThan(3),
        reason: code,
      );
    }
  });

  _demoTest('admins add a pond from the last row, not a floating button', (
    tester,
    farm,
  ) async {
    expect(find.byType(FloatingActionButton), findsNothing);
    final add = find.text('Ajouter un étang');
    expect(add, findsOneWidget);
    expect(
      tester.getTopLeft(add).dy,
      greaterThan(tester.getTopLeft(_row('P2')).dy),
    );
  });

  _demoTest('members who are not admins see no add row', isAdmin: false, (
    tester,
    farm,
  ) async {
    expect(find.text('Ajouter un étang'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  _demoTest('tapping a row opens the pond', (tester, farm) async {
    await tapAndSettle(tester, _row('E3'));
    expect(find.byType(PondDetailScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'E3'), findsOneWidget);
  });

  _demoTest('large text in Malagasy: rows wrap, nothing overflows', (
    tester,
    farm,
  ) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Dobo 3 atahorana'), findsOneWidget);
  }, size: const Size(320, 3200));

  _demoTest('ponds list golden, French', (tester, farm) async {
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/ponds_list_fr.png'),
    );
  }, size: const Size(360, 780));

  _demoTest('ponds list golden, Malagasy', (tester, farm) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/ponds_list_mg.png'),
    );
  }, size: const Size(360, 780));

  testWidgets('a stocked pond with no known weight: fish, no ration', (
    tester,
  ) async {
    // One batch whose weight is unknown: the real path through the row.
    await _pumpRow(
      tester,
      _overview(
        batches: [
          BatchInPond(
            batch: batchRow('b1', code: 'L7'),
            placement: placementOf('b1', 'p1', 800, null),
            phase: null,
            biomassG: null,
          ),
        ],
        rationG: 0,
        biomassG: null,
      ),
    );
    expect(find.text('≈\u00a0800 poissons'), findsOneWidget);
    expect(find.byKey(rationKey), findsNothing);
    expect(find.text('Ne pas nourrir'), findsNothing);
    expect(find.textContaining('kg'), findsNothing);
  });

  testWidgets('density out of range is a warning colour, not danger', (
    tester,
  ) async {
    await _pumpRow(
      tester,
      _overview(density: 7.2, densityStatus: DensityStatus.above),
    );
    final density = tester.widget<Text>(find.textContaining('Densité'));
    expect(density.style!.color, DoboColors.standard.warning);
    // Says "Densité" once: the status names it.
    expect(density.data, 'Densité trop forte : 7,2 /m²');
  });

  testWidgets('at 130 % text the ration stays on one line', (tester) async {
    await _pumpRow(tester, _overview(rationG: 12400), textScale: 1.3);
    final ration = find.descendant(
      of: find.byKey(rationKey),
      matching: find.byType(Text),
    );
    final style = doboTheme().textTheme.headlineSmall!;
    // One line of 28 sp at 1.3×, not two.
    expect(
      tester.getSize(ration).height,
      lessThan(style.fontSize! * 1.3 * 1.6),
    );
  });
}

PondOverview _overview({
  List<BatchInPond> batches = const [],
  int rationG = 0,
  int? biomassG,
  double density = 1.6,
  DensityStatus densityStatus = DensityStatus.within,
}) => PondOverview(
  pond: pondRow('p1', code: 'E7'),
  status: PondStatus.stocked,
  surfaceM2: 500,
  batches: batches,
  liveCount: 800,
  inconsistent: false,
  biomassG: biomassG,
  density: density,
  densityStatus: densityStatus,
  rationG: rationG,
);

Future<void> _pumpRow(
  WidgetTester tester,
  PondOverview overview, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(720, 1560);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: doboTheme(),
      locale: _fr,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [_fr],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: StockedPondRow(
          overview: overview,
          attention: null,
          loggedToday: false,
          stopFeeding: const {},
          onTap: () {},
        ),
      ),
    ),
  );
}
