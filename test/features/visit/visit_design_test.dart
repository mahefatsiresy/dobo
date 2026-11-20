import 'package:dobo/db/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/repositories/visit_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/pond_colour.dart';
import 'package:dobo/features/ponds/pond_detail_screen.dart';
import 'package:dobo/features/readings/water_reading_screen.dart';
import 'package:dobo/features/visit/visit_checklist.dart';
import 'package:dobo/features/visit/visit_providers.dart';
import 'package:dobo/l10n/formatting.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

/// Records made during the open visit, as the visit's own screens make them.
class _InVisit {
  _InVisit(this.db, this.session, this.visitId)
    : readings = ReadingRepository(db, session, visitId: visitId),
      observations = ObservationRepository(db, session, visitId: visitId);

  final AppDatabase db;
  final Session session;
  final String visitId;
  final ReadingRepository readings;
  final ObservationRepository observations;

  Future<void> allOk(
    String pondId, {
    Set<ObservationCategory> problems = const {},
  }) async {
    for (final c in conditionCategories) {
      await observations.addObservation(
        pondId: pondId,
        category: c,
        ok: !problems.contains(c),
      );
    }
  }
}

/// A Visit-tab test on the demo farm (unless [seed] is false), the clock at
/// [demoNow], a tall phone. With [open], a visit is started first and
/// [during] records into it; then the tab opens.
void _visitTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  Size size = const Size(360, 2400),
  bool seed = true,
  bool open = false,
  Future<void> Function(AppDatabase db, DemoFarm farm)? before,
  Future<void> Function(_InVisit v, DemoFarm farm)? during,
}) => appTest(
  description,
  overrides: [clockProvider.overrideWithValue(() => demoNow)],
  (tester, db) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final farm = seed ? await seedDemoFarm(db) : <String, String>{};
    await before?.call(db, farm);
    if (open) {
      final session = (await SetupRepository(db).currentSession())!;
      final id = await VisitRepository(db, session).start();
      // Started at the demo's "now", not the test machine's clock.
      await (db.update(db.visits)..where((v) => v.id.equals(id))).write(
        VisitsCompanion(startedAt: Value(demoNow)),
      );
      await during?.call(_InVisit(db, session, id), farm);
    }
    await tester.pumpAndSettle();
    appContainer(tester).read(routerProvider).go('/visit');
    await tester.pumpAndSettle();
    await body(tester, db);
  },
);

Finder _in(String key, Finder f) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: f);

double _top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

void main() {
  setUpAll(loadAppFonts);

  _visitTest('before a visit: what it would cover, no past visits', (
    tester,
    db,
  ) async {
    final preview = appContainer(tester).read(visitPreviewProvider)!;
    int count<T>() =>
        [for (final p in preview.ponds) ...p.checks.whereType<T>()].length;
    expect(find.text("À faire aujourd'hui"), findsOneWidget);
    expect(find.text("${count<WaterCheck>()} relevés d'eau"), findsOneWidget);
    expect(
      find.text('${count<SampleCheck>()} échantillonnages'),
      findsOneWidget,
    );
    expect(
      find.text('${count<InspectionCheck>()} étangs à inspecter'),
      findsOneWidget,
    );
    expect(find.textContaining('Dernière visite'), findsNothing);
    expect(find.text('Visites précédentes'), findsNothing);
    expect(find.text('Commencer la visite'), findsOneWidget);
  });

  _visitTest(
    'before a visit: the last one, its date and who made it',
    before: (db, farm) async {
      final session = (await SetupRepository(db).currentSession())!;
      await db
          .into(db.members)
          .insert(
            MembersCompanion.insert(
              id: Value(session.userId),
              associationId: session.associationId,
              enteredBy: session.userId,
              deviceId: session.deviceId,
              name: 'Rado',
              role: MemberRole.member,
              locale: 'fr',
            ),
          );
      final visits = VisitRepository(db, session);
      await visits.end(await visits.start());
    },
    (tester, db) async {
      final v = await db.select(db.visits).getSingle();
      expect(
        find.text('Dernière visite : ${formatDate(v.startedAt)}, Rado'),
        findsOneWidget,
      );
    },
  );

  _visitTest('starting shows the visit and none of its checks done', (
    tester,
    db,
  ) async {
    final total = appContainer(tester).read(visitPreviewProvider)!.total;
    await tapAndSettle(tester, find.text('Commencer la visite'));
    expect(find.textContaining('Visite en cours depuis'), findsOneWidget);
    expect(find.text('0 / $total'), findsOneWidget);
    // Nothing done yet: no green tick (colour means something).
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  _visitTest(
    'ending early on a small phone in Malagasy: the question scrolls into view',
    size: const Size(320, 568),
    open: true,
    (tester, db) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Hamarana ny fitsidihana'));
      final question = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Hamarana ihany ve'),
      );
      expect(
        find.ancestor(
          of: question,
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  _visitTest(
    'ponds in code order; the band between header and checks',
    open: true,
    (tester, db) async {
      final codes = [
        for (final e in find.byType(PondCode).evaluate())
          (e.widget as PondCode).code,
      ];
      expect(codes, ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'P1', 'P2']);
      // 06:00 UTC is 09:00 on the farm, whatever the phone's zone.
      expect(find.text('Visite en cours depuis 09:00'), findsOneWidget);
      final band = _in('visitBand-E2', find.byType(AttentionBand));
      expect(band, findsOneWidget);
      expect(
        _top(tester, find.byKey(const ValueKey('visitPond-E2'))),
        lessThan(_top(tester, band)),
      );
      expect(
        _top(tester, band),
        lessThan(_top(tester, find.byKey(const ValueKey('water-E2')))),
      );
      // A pond without fish is only inspected.
      expect(find.byKey(const ValueKey('water-P2')), findsNothing);
      expect(find.byKey(const ValueKey('conditions-P2')), findsOneWidget);
    },
  );

  _visitTest('the header opens the pond; the band opens its fix', open: true, (
    tester,
    db,
  ) async {
    await tapAndSettle(tester, find.byKey(const ValueKey('visitPond-E2')));
    expect(find.byType(PondDetailScreen), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton));
    await tapAndSettle(tester, _in('visitBand-E2', find.byType(AttentionBand)));
    expect(find.byType(WaterReadingScreen), findsOneWidget);
  });

  _visitTest(
    'a reading done stays with its values and opens for correction',
    open: true,
    (tester, db) async {
      final total = appContainer(tester).read(visitPreviewProvider)!.total;
      await tapAndSettle(tester, find.byKey(const ValueKey('water-E1')));
      await enterAndSettle(
        tester,
        find.widgetWithText(TextFormField, 'pH'),
        '7,2',
      );
      await tapAndSettle(tester, find.text('Enregistrer le relevé'));
      expect(_in('water-E1', find.text('pH 7,2')), findsOneWidget);
      expect(_in('water-E1', find.byIcon(Icons.check_circle)), findsOneWidget);
      expect(find.text('1 / $total'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const ValueKey('water-E1')));
      expect(find.widgetWithText(TextFormField, '7,2'), findsOneWidget);
    },
  );

  _visitTest('going to a pond and back keeps the visit', open: true, (
    tester,
    db,
  ) async {
    final total = appContainer(tester).read(visitPreviewProvider)!.total;
    await tapAndSettle(tester, find.byKey(const ValueKey('visitPond-E1')));
    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.textContaining('Visite en cours depuis'), findsOneWidget);
    expect(find.text('0 / $total'), findsOneWidget);
  });

  _visitTest(
    'a sample done shows its average and fish count',
    open: true,
    during: (v, farm) async {
      final batch = await (v.db.select(
        v.db.batches,
      )..where((b) => b.code.equals('L-E2'))).getSingle();
      await v.readings.addSample(
        SampleInput(
          batchId: batch.id,
          pondId: farm['E2']!,
          date: DateTime(2026, 3, 15),
          fishCount: 40,
          totalWeightG: 6080,
        ),
      );
    },
    (tester, db) async {
      expect(find.text('L-E2 : 152 g (40 poissons)'), findsOneWidget);
    },
  );

  _visitTest(
    'an inspection done names its problems in danger',
    open: true,
    during: (v, farm) =>
        v.allOk(farm['E1']!, problems: {ObservationCategory.dike}),
    (tester, db) async {
      expect(
        _in('conditions-E1', find.text('1 problème : Digues')),
        findsOneWidget,
      );
      expect(_in('conditions-E1', find.byIcon(Icons.error)), findsOneWidget);
    },
  );

  _visitTest(
    'an observation shows under its pond, a farm-wide one after the ponds',
    open: true,
    during: (v, farm) async {
      await v.observations.addObservation(
        pondId: farm['E2'],
        category: ObservationCategory.dike,
        note: 'Fuite côté sortie',
      );
      await v.observations.addObservation(
        category: ObservationCategory.fence,
        note: 'Clôture coupée',
      );
    },
    (tester, db) async {
      final leak = find.text('Fuite côté sortie');
      expect(
        _top(tester, leak),
        greaterThan(_top(tester, find.byKey(const ValueKey('visitPond-E2')))),
      );
      expect(
        _top(tester, leak),
        lessThan(_top(tester, find.byKey(const ValueKey('visitPond-E3')))),
      );
      expect(
        _top(tester, find.text('Clôture coupée')),
        greaterThan(_top(tester, find.text('Observations'))),
      );
      expect(
        _top(tester, find.text('Observations')),
        greaterThan(_top(tester, find.byKey(const ValueKey('visitPond-P2')))),
      );
    },
  );

  _visitTest(
    'biosecurity is a folded reminder; no checkboxes, no summary',
    open: true,
    (tester, db) async {
      expect(find.text('Biosécurité'), findsOneWidget);
      expect(find.text('7 rappels'), findsOneWidget);
      expect(find.textContaining('Pédiluve'), findsNothing);
      await tapAndSettle(tester, find.text('Biosécurité'));
      expect(find.textContaining('Pédiluve'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(TextField), findsNothing);
    },
  );

  _visitTest(
    'ending names the checks left, then opens the report draft',
    seed: false,
    open: true,
    before: (db, farm) async {
      final session = (await SetupRepository(db).currentSession())!;
      final ponds = PondRepository(db, session);
      farm['E2'] = await ponds.create(
        const PondInput(
          code: 'E2',
          colour: PondColour.yellow,
          role: PondRole.growout,
        ),
      );
      farm['E3'] = await ponds.create(
        const PondInput(
          code: 'E3',
          colour: PondColour.green,
          role: PondRole.growout,
        ),
      );
      await BatchRepository(db, session).stockBatch(
        StockInput(
          code: 'L-E2',
          pondId: farm['E2']!,
          date: DateTime(2026, 3, 10),
          count: 1000,
          avgWeightMg: 20000,
        ),
      );
    },
    during: (v, farm) => v.allOk(farm['E2']!),
    (tester, db) async {
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.bottomNavigationBar, isNotNull);
      await tapAndSettle(tester, find.text('Terminer la visite'));
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining('2 contrôles pas faits'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('relevé E2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('état E3')),
        findsOneWidget,
      );
      await tapAndSettle(
        tester,
        find.descendant(of: dialog, matching: find.text('Terminer la visite')),
      );
      expect(find.text('Rapport de visite'), findsOneWidget);
    },
  );

  _visitTest(
    'ending with nothing left asks the usual question',
    seed: false,
    open: true,
    before: (db, farm) async {
      final session = (await SetupRepository(db).currentSession())!;
      farm['P1'] = await PondRepository(db, session).create(
        const PondInput(
          code: 'P1',
          colour: PondColour.black,
          role: PondRole.growout,
        ),
      );
    },
    during: (v, farm) => v.allOk(farm['P1']!),
    (tester, db) async {
      await tapAndSettle(tester, find.text('Terminer la visite'));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Le rapport sera préparé'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('pas fait'), findsNothing);
    },
  );

  for (final open in [false, true]) {
    _visitTest(
      'large text in Malagasy: nothing overflows (${open ? 'during' : 'before'})',
      size: const Size(320, 3200),
      open: open,
      during: (v, farm) async {
        await v.allOk(farm['E1']!, problems: {ObservationCategory.dike});
        final batch = await (v.db.select(
          v.db.batches,
        )..where((b) => b.code.equals('L-E2'))).getSingle();
        await v.readings.addSample(
          SampleInput(
            batchId: batch.id,
            pondId: farm['E2']!,
            date: DateTime(2026, 3, 15),
            fishCount: 40,
            totalWeightG: 6080,
          ),
        );
        await v.observations.addObservation(
          pondId: farm['E2'],
          category: ObservationCategory.dike,
          note: 'Fuite côté sortie',
        );
      },
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

  _visitTest('visit start golden fr', size: const Size(360, 780), (
    tester,
    db,
  ) async {
    await expectLater(
      find.byType(Scaffold).last,
      matchesGoldenFile('goldens/visit_start_fr.png'),
    );
  });

  for (final locale in ['fr', 'mg']) {
    _visitTest(
      'visit golden $locale',
      size: const Size(360, 780),
      open: true,
      during: (v, farm) async {
        await v.readings.addWaterReading(
          WaterReadingInput(
            pondId: farm['E1']!,
            at: demoNow,
            temperatureC: 28,
            ph: 7.2,
            oxygenMgL: 5,
          ),
        );
        await v.allOk(farm['E1']!);
      },
      (tester, db) async {
        appContainer(tester)
            .read(localeControllerProvider.notifier)
            .set(Locale(locale));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).last,
          matchesGoldenFile('goldens/visit_$locale.png'),
        );
      },
    );
  }
}
