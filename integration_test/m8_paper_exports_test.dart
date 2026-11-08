import 'dart:io';

import 'package:dobo/app.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/exports/csv.dart';
import 'package:dobo/features/reports/share_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/paper/paper_sheet_pdf_test.dart' show pageCount;
import '../test/helpers.dart';

/// M8 milestone walk-through on a device, against the real database. Run it
/// in airplane mode on a freshly cleared app:
///   adb shell pm clear mg.dobo.dobo
///   flutter test integration_test/m8_paper_exports_test.dart -d DEVICE
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  final shared = <File>[];

  testWidgets('print paper sheets, copy one back, export the register and '
      'switch to Malagasy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportSharerProvider.overrideWithValue((f) async => shared.add(f)),
        ],
        child: const DoboApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DoboApp)),
    );
    final db = container.read(databaseProvider);

    /// Taps [button] and waits for the file it shares: PDFs and files are
    /// built off the test clock.
    Future<File> shareBy(Finder button) async {
      final before = shared.length;
      await tester.tap(button);
      for (var i = 0; i < 100 && shared.length == before; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      }
      await tester.pumpAndSettle();
      expect(shared, hasLength(before + 1));
      return shared.last;
    }

    // Setup: E1 and E2 stocked 20 days ago, a week of logs on E1, and the
    // worker whose paper sheet is copied.
    await enterAndSettle(tester, field('Nom du site'), 'Ambohidratrimo');
    await tapAndSettle(tester, find.text('Commencer'));
    final today = farmDate(DateTime.now().toUtc());
    DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);
    final ponds = container.read(pondRepositoryProvider);
    final e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    final e2 = await ponds.create(
      const PondInput(
        code: 'E2',
        colour: PondColour.yellow,
        role: PondRole.growout,
      ),
    );
    final batches = container.read(batchRepositoryProvider);
    for (final (code, pond) in [('L1', e1), ('L2', e2)]) {
      await batches.stockBatch(
        StockInput(
          code: code,
          pondId: pond,
          date: daysAgo(20),
          count: 1000,
          avgWeightMg: 20000,
        ),
      );
    }
    final logs = container.read(dailyLogRepositoryProvider);
    for (var n = 7; n >= 1; n--) {
      await logs.save(
        DailyLogInput(pondId: e1, date: daysAgo(n), feedGivenG: 3000),
      );
    }
    await container.read(personRepositoryProvider).create(name: 'Rakoto');
    await tester.pumpAndSettle();

    // 1. Paper sheets: E1 only, 2 weeks, shared as a PDF of 2 pages.
    await tapAndSettle(tester, tab('Plus'));
    await reveal(tester, find.text('Fiches papier'));
    await tapAndSettle(tester, find.text('Fiches papier'));
    await tapAndSettle(tester, find.byKey(const ValueKey('paperPond-E2')));
    await tapAndSettle(tester, find.byKey(const ValueKey('paperWeeks-2')));
    final sheet = await shareBy(find.text('Partager le PDF'));
    expect(sheet.path, contains('fiches-'));
    expect(pageCount(sheet.readAsBytesSync()), 2);
    await tapAndSettle(tester, find.byTooltip('Retour'));

    // 2. Transcription: today's E1 box, with a little left over and dark
    // green water.
    await reveal(tester, find.text('Saisie des fiches'));
    await tapAndSettle(tester, find.text('Saisie des fiches'));
    await tapAndSettle(tester, find.byKey(const ValueKey('sheetOf')));
    await tapAndSettle(tester, find.text('Rakoto').last);
    String iso(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    await reveal(tester, find.byKey(ValueKey('kg-$e1-${iso(today)}')));
    await enterAndSettle(
      tester,
      find.byKey(ValueKey('kg-$e1-${iso(today)}')),
      '2,5',
    );
    await tapAndSettle(tester, find.byKey(ValueKey('signs-$e1-${iso(today)}')));
    await tapAndSettle(tester, find.text('Un peu de reste'));
    await reveal(tester, find.byKey(const ValueKey(WaterColour.darkGreen)));
    await tapAndSettle(
      tester,
      find.byKey(const ValueKey(WaterColour.darkGreen)),
    );
    await reveal(tester, find.text('Fermer'));
    await tapAndSettle(tester, find.text('Fermer'));
    await reveal(tester, find.text('Enregistrer'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    final copied = (await db.select(
      db.dailyLogs,
    ).get()).singleWhere((l) => l.observedBy != null);
    expect((copied.feedGivenG, copied.leftover, copied.waterColour), (
      2500,
      Leftover.some,
      WaterColour.darkGreen,
    ));
    await tapAndSettle(tester, find.byTooltip('Retour'));

    // 3. Exports: the register CSV of the last 30 days, then the weekly PDF.
    await reveal(tester, find.text('Exports'));
    await tapAndSettle(tester, find.text('Exports'));
    final csv = await shareBy(find.text('CSV'));
    expect(csv.path, contains('registre-Ambohidratrimo-'));
    final rows = decodeCsv(csv.readAsStringSync());
    // Header, two stockings, seven logs and today's copied box.
    expect(rows, hasLength(11));
    await tapAndSettle(tester, find.text('Suivi hebdomadaire (annexe B)'));
    final weekly = await shareBy(find.text('PDF'));
    expect(weekly.path, contains('suivi-hebdo-'));
    expect(String.fromCharCodes(weekly.readAsBytesSync().take(4)), '%PDF');
    await tapAndSettle(tester, find.byTooltip('Retour'));

    // 4. Malagasy: the tabs and the exports screen are no longer French.
    await reveal(tester, find.text('Langue'));
    await tapAndSettle(tester, find.text('Langue'));
    await tapAndSettle(tester, find.text('Malagasy'));
    expect(tab('Dobo'), findsOneWidget);
    await reveal(tester, find.text('Fanondranana'));
    await tapAndSettle(tester, find.text('Fanondranana'));
    expect(find.text('Rejisitra famokarana (tovana A)'), findsOneWidget);
  });
}
