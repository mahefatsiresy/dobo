import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/choice_buttons.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/pond_choice.dart';
import 'package:dobo/features/exports/exports_screen.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _exportsTest(
  String description,
  String path,
  Future<void> Function(WidgetTester tester) body, {
  Size size = const Size(360, 1100),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await seedDemoFarm(db);
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go(path);
  await tester.pumpAndSettle();
  await body(tester);
});

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _exportsTest(
    'kind buttons, pond buttons, PDF pinned, CSV above it',
    '/more/exports',
    (tester) async {
      expect(find.byType(ChoiceButtons<ExportKind>), findsOneWidget);
      expect(find.byType(PondChoice), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is DropdownButtonFormField || w is ChoiceChip,
        ),
        findsNothing,
      );
      expect(find.text('Tous les étangs'), findsOneWidget);
      await tapAndSettle(tester, find.text('E2'));
      expect(find.text('Tous les étangs'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SafeArea),
          matching: find.widgetWithText(FilledButton, 'PDF'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'CSV'), findsOneWidget);
    },
  );

  _exportsTest(
    'an end before the start: a danger band under the dates',
    '/more/exports?from=2026-03-10&to=2026-03-01',
    (tester) async {
      final band = find.ancestor(
        of: find.text('La date de fin est avant la date de début.'),
        matching: find.byType(AttentionBand),
      );
      expect(band, findsOneWidget);
      expect(tester.widget<AttentionBand>(band).severity, BandSeverity.danger);
    },
  );

  _exportsTest('large Malagasy text does not overflow', '/more/exports', (
    tester,
  ) async {
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  _exportsTest('exports golden', '/more/exports', (tester) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/exports_fr.png'),
    );
  }, size: const Size(360, 780));
}
