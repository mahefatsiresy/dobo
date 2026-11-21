import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/prep_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/l10n/formatting.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

/// P1 of the demo farm: drained 8 days ago, dried yesterday.
void _prepTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db, DemoFarm farm)
  body, {
  Size size = const Size(360, 1200),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final farm = await seedDemoFarm(db);
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go('/ponds/${farm['P1']}/prep');
  await tester.pumpAndSettle();
  await body(tester, db, farm);
});

Finder _step(PrepStep s) => find.byKey(ValueKey('step-${s.name}'));

Finder _pinned(String label) => find.descendant(
  of: find.byType(SafeArea),
  matching: find.widgetWithText(FilledButton, label),
);

Future<PrepRepository> _repo(AppDatabase db) async =>
    PrepRepository(db, (await SetupRepository(db).currentSession())!);

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _prepTest('six numbered steps: done, next, to come', (
    tester,
    db,
    farm,
  ) async {
    for (final (i, s) in PrepStep.values.indexed) {
      expect(
        find.descendant(of: _step(s), matching: find.text('${i + 1}')),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: _step(PrepStep.drain),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _step(PrepStep.treat),
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsOneWidget,
    );
    expect(find.text("Fait aujourd'hui"), findsOneWidget);
    expect(
      find.descendant(
        of: _step(PrepStep.fill),
        matching: find.byIcon(Icons.radio_button_unchecked),
      ),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNothing);
    expect(_pinned('Prêt à empoissonner'), findsNothing);
  });

  _prepTest(
    'treating opens its page with today and the handbook dose as a hint',
    (tester, db, farm) async {
      await tapAndSettle(tester, find.text("Fait aujourd'hui"));
      expect(find.text('15/03/2026'), findsOneWidget);
      // The handbook's range is a hint, never a dose nobody weighed.
      final dose = find.widgetWithText(TextFormField, 'Dose utilisée');
      expect(tester.widget<TextFormField>(dose).controller!.text, isEmpty);
      expect(find.text('50–100 kg'), findsOneWidget);
      await tapAndSettle(tester, find.text('Chaux vive'));
      await tapAndSettle(tester, _pinned("Enregistrer l'étape"));
      final p = await (await _repo(db)).progress(farm['P1']!);
      expect(p.done.keys, contains(PrepStep.treat));
      expect(p.done[PrepStep.treat]!.doseG, isNull);
      expect(p.next, PrepStep.fertilise);
    },
  );

  _prepTest('a step without a product is done in one tap', (
    tester,
    db,
    farm,
  ) async {
    final repo = await _repo(db);
    await repo.record(farm['P1']!, PrepStep.treat, on: DateTime(2026, 3, 14));
    await repo.record(
      farm['P1']!,
      PrepStep.fertilise,
      on: DateTime(2026, 3, 14),
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text("Fait aujourd'hui"));
    expect(find.text('Étape enregistrée'), findsOneWidget);
    final p = await repo.progress(farm['P1']!);
    expect(formatDate(p.done[PrepStep.fill]!.date), '15/03/2026');
    expect(_pinned('Prêt à empoissonner'), findsOneWidget);
  });

  _prepTest('a done step opens to correct; ⋮ names it to delete', (
    tester,
    db,
    farm,
  ) async {
    await tapAndSettle(tester, _step(PrepStep.drain));
    expect(_pinned("Enregistrer l'étape"), findsOneWidget);
    await tapAndSettle(tester, find.byIcon(Icons.more_vert));
    await tapAndSettle(tester, find.text('Supprimer'));
    expect(
      find.text("Supprimer l'étape Vidange et curage du 07/03/2026 ?"),
      findsOneWidget,
    );
  });

  _prepTest('marking ready shows the skipped steps as a band', (
    tester,
    db,
    farm,
  ) async {
    final repo = await _repo(db);
    await repo.record(farm['P1']!, PrepStep.fill, on: DateTime(2026, 3, 15));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, _pinned('Prêt à empoissonner'));
    expect(
      find.ancestor(
        of: find.textContaining('Étapes non faites'),
        matching: find.byType(AttentionBand),
      ),
      findsOneWidget,
    );
  });

  _prepTest('large Malagasy text does not overflow', (tester, db, farm) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, size: const Size(360, 1800));

  for (final locale in ['fr', 'mg']) {
    _prepTest('prep golden ($locale)', (tester, db, farm) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prep_$locale.png'),
      );
    }, size: const Size(360, 780));
  }
}
