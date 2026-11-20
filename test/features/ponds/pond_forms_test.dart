import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/facts_repository.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/choice_buttons.dart';
import 'package:dobo/features/common/details_fold.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _formTest(
  String description,
  String Function(DemoFarm farm, Map<String, String> batches) path,
  Future<void> Function(WidgetTester tester, AppDatabase db, DemoFarm farm)
  body, {
  Size size = const Size(480, 900),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final farm = await seedDemoFarm(db);
  final batches = {
    for (final b in await db.select(db.batches).get()) b.code: b.id,
  };
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go(path(farm, batches));
  await tester.pumpAndSettle();
  await body(tester, db, farm);
});

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Finder _pinned(String label) => find.descendant(
  of: find.byType(SafeArea),
  matching: find.widgetWithText(FilledButton, label),
);

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _formTest(
    'water reading: low oxygen is a danger band under it',
    (farm, _) => '/water/${farm['E1']}',
    (tester, db, farm) async {
      expect(_pinned('Enregistrer le relevé'), findsOneWidget);
      await enterAndSettle(tester, _field('Oxygène dissous'), '2');
      final band = find.byType(AttentionBand);
      expect(band, findsOneWidget);
      expect(tester.widget<AttentionBand>(band).severity, BandSeverity.danger);
      expect(
        tester.getTopLeft(band).dy,
        greaterThan(tester.getBottomLeft(_field('Oxygène dissous')).dy),
      );
    },
  );

  _formTest('water reading correction: named delete', (farm, _) => '/ponds', (
    tester,
    db,
    farm,
  ) async {
    final reading = (await currentEvents(
      db,
      db.waterReadings,
    ).get()).firstWhere((r) => r.pondId == farm['E1']);
    appContainer(tester)
        .read(routerProvider)
        .go('/water/${farm['E1']}?readingId=${reading.id}');
    await tester.pumpAndSettle();
    expect(_pinned('Enregistrer la correction'), findsOneWidget);
    await tapAndSettle(tester, find.byIcon(Icons.more_vert));
    await tapAndSettle(tester, find.text('Supprimer'));
    expect(
      find.text("Supprimer le relevé d'eau du 15/03/2026 ?"),
      findsOneWidget,
    );
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Supprimer'),
      ),
    );
    expect(
      (await currentEvents(
        db,
        db.waterReadings,
      ).get()).where((r) => r.id == reading.id),
      isEmpty,
    );
  });

  _formTest(
    'sample: small sample is a warning band; correction has ⋮',
    (farm, batches) => '/sample/${farm['E1']}?batchId=${batches['L-E1']}',
    (tester, db, farm) async {
      expect(_pinned('Enregistrer la pesée'), findsOneWidget);
      await enterAndSettle(tester, _field('Poissons pesés'), '10');
      await enterAndSettle(tester, _field('Poids total'), '1,5');
      final band = find.byType(AttentionBand);
      expect(band, findsOneWidget);
      expect(tester.widget<AttentionBand>(band).severity, BandSeverity.warning);
      await tapAndSettle(tester, _pinned('Enregistrer la pesée'));
      final sample = (await currentEvents(db, db.samples).get()).last;
      expect(sample.fishCount, 10);
      appContainer(tester)
          .read(routerProvider)
          .go(
            '/sample/${farm['E1']}?batchId=${sample.batchId}'
            '&sampleId=${sample.id}',
          );
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.byIcon(Icons.more_vert));
      await tapAndSettle(tester, find.text('Supprimer'));
      expect(find.textContaining('Supprimer la pesée du'), findsOneWidget);
    },
  );

  _formTest(
    'treatment: batch and adviser folded',
    (farm, _) => '/ponds/${farm['E1']}/treatment',
    (tester, db, farm) async {
      expect(find.byType(DropdownButtonFormField<String?>), findsNothing);
      expect(_field('Conseillé par'), findsNothing);
      expect(_pinned('Enregistrer le traitement'), findsOneWidget);
      await tapAndSettle(tester, find.text('Plus de détails'));
      expect(_field('Conseillé par'), findsOneWidget);
      expect(find.byType(ChoiceButtons<String?>), findsOneWidget);
    },
  );

  _formTest(
    'Signaler: isolate is a switch row',
    (farm, _) => '/ponds/${farm['E1']}/problem',
    (tester, db, farm) async {
      expect(_pinned('Signaler'), findsOneWidget);
      final row = find.widgetWithText(SwitchListTile, "Isoler l'étang");
      await reveal(tester, row);
      expect(row, findsOneWidget);
      expect(tester.getSize(row).height, greaterThanOrEqualTo(56));
    },
  );

  _formTest(
    'pond form: buttons, details folded, Ajouter un étang',
    (_, _) => '/ponds/new',
    (tester, db, farm) async {
      expect(find.byType(DropdownButtonFormField<dynamic>), findsNothing);
      expect(find.byType(DetailsFold), findsOneWidget);
      expect(_field("Profondeur à l'entrée"), findsNothing);
      expect(_field('Longueur'), findsOneWidget);
      expect(_pinned('Ajouter un étang'), findsOneWidget);
      await enterAndSettle(tester, _field('Longueur'), '200');
      await enterAndSettle(tester, _field('Largeur'), '1');
      final band = find.byType(AttentionBand);
      expect(band, findsWidgets);
      expect(
        tester.getTopLeft(band.first).dy,
        greaterThan(tester.getBottomLeft(_field('Largeur')).dy),
      );
    },
  );

  _formTest(
    'pond form editing: Enregistrer l\'étang',
    (farm, _) => '/ponds/${farm['E1']}/edit',
    (tester, db, farm) async {
      expect(_pinned("Enregistrer l'étang"), findsOneWidget);
    },
  );

  _formTest(
    'person form: phone and note folded',
    (_, _) => '/more/people/new',
    (tester, db, farm) async {
      expect(_field('Téléphone'), findsNothing);
      expect(_pinned('Ajouter la personne'), findsOneWidget);
    },
  );

  for (final (name, path)
      in <(String, String Function(DemoFarm, Map<String, String>))>[
        ('water', (f, _) => '/water/${f['E1']}'),
        ('sample', (f, b) => '/sample/${f['E1']}?batchId=${b['L-E1']}'),
        ('treatment', (f, _) => '/ponds/${f['E1']}/treatment'),
        ('problem', (f, _) => '/ponds/${f['E1']}/problem'),
        ('pond', (_, _) => '/ponds/new'),
        ('person', (_, _) => '/more/people/new'),
      ]) {
    _formTest('$name: large Malagasy text does not overflow', path, (
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
    }, size: const Size(360, 780));
  }

  _formTest('pond form golden', (_, _) => '/ponds/new', (
    tester,
    db,
    farm,
  ) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pond_form_fr.png'),
    );
  }, size: const Size(360, 780));
}
