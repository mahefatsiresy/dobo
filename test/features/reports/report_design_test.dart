import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/repositories/visit_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/coded_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/visit/visit_checklist.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

/// A visit on the demo farm at [demoNow]: E1 read and all in order, a dike
/// problem on E3; ended, its draft open, and published unless [draft].
void _reportTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  Size size = const Size(360, 3600),
  bool draft = false,
  bool seed = true,
}) => appTest(
  description,
  overrides: [clockProvider.overrideWithValue(() => demoNow)],
  (tester, db) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final farm = seed ? await seedDemoFarm(db) : <String, String>{};
    final session = (await SetupRepository(db).currentSession())!;
    final visits = VisitRepository(db, session);
    final id = await visits.start();
    if (seed) {
      await ReadingRepository(db, session, visitId: id).addWaterReading(
        WaterReadingInput(
          pondId: farm['E1']!,
          at: demoNow,
          temperatureC: 28,
          ph: 7.2,
          oxygenMgL: 5,
        ),
      );
      final obs = ObservationRepository(db, session, visitId: id);
      for (final c in conditionCategories) {
        await obs.addObservation(pondId: farm['E1'], category: c, ok: true);
        await obs.addObservation(
          pondId: farm['E3'],
          category: c,
          ok: c != ObservationCategory.dike,
          note: c == ObservationCategory.dike ? 'Fuite côté sortie' : null,
        );
      }
    }
    await visits.setSummary(id, 'Eau verte, poissons actifs.');
    await visits.end(id);
    await (db.update(db.visits)..where((v) => v.id.equals(id))).write(
      VisitsCompanion(startedAt: Value(demoNow), endedAt: Value(demoNow)),
    );
    await tester.pumpAndSettle();
    appContainer(tester).read(routerProvider).go('/reports/draft/$id');
    await tester.pumpAndSettle();
    if (!draft) await tapAndSettle(tester, find.text('Publier'));
    await body(tester, db);
  },
);

double _top(WidgetTester t, Finder f) => t.getTopLeft(f.first).dy;

void main() {
  setUpAll(loadAppFonts);

  _reportTest('sections in F8 order', (tester, db) async {
    final tops = [
      for (final h in const [
        'Résumé',
        'Alertes',
        'Santé',
        'Eau',
        'Croissance',
        'Aliment',
        'À venir',
        'Observations et photos',
      ])
        _top(tester, find.text(h)),
    ];
    expect(tops, [...tops]..sort());
  });

  _reportTest('alerts are bands, danger first, not tappable', (
    tester,
    db,
  ) async {
    final bands = tester.widgetList<CodedBand>(find.byType(CodedBand)).toList();
    expect(bands, isNotEmpty);
    final firstWarning = bands.indexWhere(
      (b) => b.severity == BandSeverity.warning,
    );
    expect(
      bands.skip(firstWarning).every((b) => b.severity == BandSeverity.warning),
      isTrue,
    );
    expect(bands.every((b) => b.onTap == null), isTrue);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  // The order (signs and events first, then deaths) is unit-tested in
  // report_order_test.dart: the demo farm's health event is stamped with
  // the real clock, outside this report's period.
  _reportTest('health: a pond\'s deaths under its code', (tester, db) async {
    final deaths = find.textContaining(RegExp(r'^500 morts($| \()'));
    expect(deaths, findsOneWidget);
    final row = find.ancestor(of: deaths, matching: find.byType(Row)).first;
    expect(find.descendant(of: row, matching: find.text('E5')), findsOneWidget);
  });

  _reportTest('water: one line per pond, low oxygen marked', (
    tester,
    db,
  ) async {
    final o2 = find.text('O₂ 2 mg/L');
    expect(o2, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: o2, matching: find.byType(Wrap)).first,
        matching: find.byIcon(Icons.error),
      ),
      findsOneWidget,
    );
  });

  _reportTest('estimates start with ≈ on screen, never "estimé"', (
    tester,
    db,
  ) async {
    expect(find.textContaining('≈', findRichText: true), findsWidgets);
    expect(find.textContaining('estimé', findRichText: true), findsNothing);
  });

  _reportTest('feed has a total row', (tester, db) async {
    expect(find.text('Total'), findsOneWidget);
  });

  _reportTest('observations: the problem, then the ponds in order', (
    tester,
    db,
  ) async {
    final problem = find.textContaining('Fuite côté sortie');
    final inOrder = find.text('Tout en ordre : E1');
    expect(inOrder, findsOneWidget);
    expect(_top(tester, problem), lessThan(_top(tester, inOrder)));
  });

  _reportTest('published: Partager is pinned, no share icon above', (
    tester,
    db,
  ) async {
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.bottomNavigationBar, isNotNull);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.share),
      ),
      findsNothing,
    );
    expect(find.text('Partager'), findsOneWidget);
  });

  _reportTest(
    'the draft: who sees it, and the summary box first',
    draft: true,
    (tester, db) async {
      expect(
        find.text("Brouillon : visible par vous seul jusqu'à la publication"),
        findsOneWidget,
      );
      final box = find.byType(TextField);
      expect(box, findsOneWidget);
      expect(
        tester.widget<TextField>(box).decoration?.hintText,
        'Ce que vous avez vu, en quelques mots',
      );
      expect(_top(tester, box), lessThan(_top(tester, find.text('Alertes'))));
      expect(find.text('Publier'), findsOneWidget);
    },
  );

  _reportTest('a farm with no fish says what nothing means', seed: false, (
    tester,
    db,
  ) async {
    expect(find.text('Aucune alerte'), findsOneWidget);
    expect(find.text('Aucun mort, aucun signe'), findsOneWidget);
    expect(find.text('Rien de prévu'), findsOneWidget);
  });

  for (final draft in [false, true]) {
    _reportTest(
      'large text in Malagasy: nothing overflows (${draft ? 'draft' : 'published'})',
      size: const Size(320, 4800),
      draft: draft,
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
  }

  Future<void> golden(WidgetTester tester, String name) => expectLater(
    find.byType(Scaffold).last,
    matchesGoldenFile('goldens/$name.png'),
  );

  _reportTest('report golden fr top', size: const Size(360, 780), (
    tester,
    db,
  ) async {
    await golden(tester, 'report_fr_top');
  });

  _reportTest('report golden fr bottom', size: const Size(360, 780), (
    tester,
    db,
  ) async {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -6000));
    await tester.pumpAndSettle();
    await golden(tester, 'report_fr_bottom');
  });

  _reportTest('report golden mg top', size: const Size(360, 780), (
    tester,
    db,
  ) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    await tester.pumpAndSettle();
    await golden(tester, 'report_mg_top');
  });

  _reportTest(
    'report draft golden fr',
    size: const Size(360, 780),
    draft: true,
    (tester, db) async {
      await golden(tester, 'report_draft_fr');
    },
  );
}
