import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/facts_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/daily_log/daily_log_screen.dart';
import 'package:dobo/features/transcription/transcription_screen.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _sheetTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db, DemoFarm farm)
  body, {
  Size size = const Size(360, 1200),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final farm = await seedDemoFarm(db);
  await seedDemoAdmin(db, farm);
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go('/more/transcription');
  await tester.pumpAndSettle();
  await body(tester, db, farm);
});

/// 09/03/2026 to 15/03/2026: the demo's week.
String _day(int d) => '2026-03-${d.toString().padLeft(2, '0')}';

Finder _kg(int d) => find.byKey(ValueKey('kg-${_day(d)}'));
Finder _deaths(int d) => find.byKey(ValueKey('deaths-${_day(d)}'));

Finder _pinned(String label) => find.descendant(
  of: find.byType(SafeArea),
  matching: find.widgetWithText(FilledButton, label),
);

Future<void> _pickRakoto(WidgetTester tester) async {
  await tapAndSettle(tester, find.byKey(const ValueKey('sheet-of')));
  await tapAndSettle(tester, find.text('Rakoto'));
}

Future<void> _pond(WidgetTester tester, DemoFarm farm, String code) =>
    tapAndSettle(tester, find.byKey(ValueKey('pond-${farm[code]}')));

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _sheetTest('the worker picker lists people without an account first', (
    tester,
    db,
    farm,
  ) async {
    await tapAndSettle(tester, find.byKey(const ValueKey('sheet-of')));
    final rakoto = tester.getTopLeft(find.text('Rakoto')).dy;
    final members = find.textContaining('(membre)');
    expect(members, findsWidgets);
    expect(rakoto, lessThan(tester.getTopLeft(members.first).dy));
    expect(find.text('Soa'), findsNothing); // inactive
  });

  _sheetTest('a logged day is one line that opens its log', (
    tester,
    db,
    farm,
  ) async {
    final logged = find.byKey(ValueKey('logged-${_day(10)}'));
    expect(logged, findsOneWidget);
    expect(
      find.descendant(of: logged, matching: find.text('déjà saisi')),
      findsOneWidget,
    );
    expect(_kg(10), findsNothing);
    await tapAndSettle(tester, logged);
    expect(find.byType(DailyLogScreen), findsOneWidget);
  });

  _sheetTest('a pond whose week is all logged shows ✓', (
    tester,
    db,
    farm,
  ) async {
    final session = (await SetupRepository(db).currentSession())!;
    await DailyLogRepository(db, session).saveWeek([
      for (var d = 9; d <= 15; d++)
        DailyLogInput(
          pondId: farm['E3']!,
          date: DateTime(2026, 3, d),
          feedGivenG: 1000,
        ),
    ]);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(ValueKey('pond-${farm['E3']}')),
        matching: find.text('✓'),
      ),
      findsOneWidget,
    );
  });

  _sheetTest('typing survives a switch; the dot marks unsaved sheets', (
    tester,
    db,
    farm,
  ) async {
    await _pickRakoto(tester);
    await _pond(tester, farm, 'E2');
    await enterAndSettle(tester, _kg(9), '5');
    await _pond(tester, farm, 'E3');
    expect(
      find.descendant(
        of: find.byKey(ValueKey('pond-${farm['E2']}')),
        matching: find.text('•'),
      ),
      findsOneWidget,
    );
    await enterAndSettle(tester, _kg(9), '4');
    await tapAndSettle(tester, _pinned('Enregistrer la fiche E3'));
    await _pond(tester, farm, 'E2');
    expect(tester.widget<TextField>(_kg(9)).controller!.text, '5');
    await tapAndSettle(tester, find.byType(BackButton));
    expect(
      find.text('Quitter sans enregistrer les fiches E2 ?'),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.text('Rester'));
    expect(find.byType(TranscriptionScreen), findsOneWidget);
  });

  _sheetTest('deaths without feed: a band, nothing saved', (
    tester,
    db,
    farm,
  ) async {
    await _pickRakoto(tester);
    await _pond(tester, farm, 'E2');
    final before = (await currentEvents(db, db.dailyLogs).get()).length;
    await enterAndSettle(tester, _deaths(12), '2');
    await tapAndSettle(tester, _pinned('Enregistrer la fiche E2'));
    expect(
      find.ancestor(
        of: find.textContaining("la quantité d'aliment manque"),
        matching: find.byType(AttentionBand),
      ),
      findsOneWidget,
    );
    expect((await currentEvents(db, db.dailyLogs).get()).length, before);
  });

  _sheetTest('saving a sheet: observed by the worker, the next pond picked', (
    tester,
    db,
    farm,
  ) async {
    await _pickRakoto(tester);
    await _pond(tester, farm, 'E1');
    await enterAndSettle(tester, _kg(9), '7,4');
    await enterAndSettle(tester, _deaths(9), '1');
    await tapAndSettle(tester, _pinned('Enregistrer la fiche E1'));
    expect(find.text('Fiche E1 enregistrée'), findsOneWidget);
    final log = (await currentEvents(db, db.dailyLogs).get()).singleWhere(
      (l) => l.pondId == farm['E1'] && l.recordedAt.day == 9,
    );
    expect((log.feedGivenG, log.deaths), (7400, 1));
    expect(log.observedBy, farm['Rakoto']);
    // The days logged before stay as they were (10, 11 and 15).
    expect(
      (await currentEvents(
        db,
        db.dailyLogs,
      ).get()).where((l) => l.pondId == farm['E1']).length,
      4,
    );
    expect(_pinned('Enregistrer la fiche E2'), findsOneWidget);
  });

  _sheetTest('no worker picked: nothing saved', (tester, db, farm) async {
    await _pond(tester, farm, 'E2');
    await enterAndSettle(tester, _kg(9), '5');
    await tapAndSettle(tester, _pinned('Enregistrer la fiche E2'));
    expect(find.text('Obligatoire'), findsOneWidget);
  });

  _sheetTest('the + page: what was picked shows on the row and is saved', (
    tester,
    db,
    farm,
  ) async {
    await _pond(tester, farm, 'E2');
    await tapAndSettle(tester, find.byKey(ValueKey('details-${_day(9)}')));
    await tapAndSettle(tester, find.text('Un peu de reste'));
    await tapAndSettle(tester, find.text('Terminé'));
    expect(
      find.descendant(
        of: find.byKey(ValueKey('details-${_day(9)}')),
        matching: find.byKey(const ValueKey('picked-leftover')),
      ),
      findsOneWidget,
    );
    // Saved with the sheet.
    await _pickRakoto(tester);
    await enterAndSettle(tester, _kg(9), '3');
    await tapAndSettle(tester, _pinned('Enregistrer la fiche E2'));
    final log = (await currentEvents(db, db.dailyLogs).get()).singleWhere(
      (l) => l.pondId == farm['E2'] && l.recordedAt.day == 9,
    );
    expect(log.leftover, Leftover.some);
  });

  _sheetTest('large Malagasy text: no overflow, nothing sideways', (
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
    expect(
      find.byWidgetPredicate(
        // Text fields scroll their own text sideways; the page must not.
        (w) =>
            w is Scrollable &&
            w.axisDirection == AxisDirection.right &&
            w.restorationId != 'editable',
      ),
      findsNothing,
    );
  }, size: const Size(360, 1600));

  for (final locale in ['fr', 'mg']) {
    _sheetTest('transcription golden ($locale)', (tester, db, farm) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      await _pickRakoto(tester);
      await enterAndSettle(tester, _kg(9), '7,4');
      await tester.drag(find.byType(ListView).first, const Offset(0, 800));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/transcription_$locale.png'),
      );
    }, size: const Size(360, 780));
  }
}
