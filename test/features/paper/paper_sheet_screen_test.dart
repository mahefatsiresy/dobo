import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/paper/print_pdf.dart';
import 'package:dobo/features/reports/share_report.dart';
import 'package:dobo/features/sync/backup_actions.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import 'paper_sheet_pdf_test.dart' show pageCount;

void main() {
  final printed = <(String, Uint8List)>[];
  final shared = <File>[];
  final overrides = [
    // Wednesday 11/11/2026, 09:00 in Madagascar.
    clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 11, 6)),
    pdfPrinterProvider.overrideWithValue(
      (name, bytes) async => printed.add((name, bytes)),
    ),
    reportSharerProvider.overrideWithValue((file) async => shared.add(file)),
    backupDirProvider.overrideWithValue(
      () async => Directory.systemTemp.createTemp('dobo-paper'),
    ),
  ];

  setUp(() {
    printed.clear();
    shared.clear();
  });

  Future<void> open(WidgetTester tester, AppDatabase db) async {
    final session = (await SetupRepository(db).currentSession())!;
    for (final (code, colour) in [
      ('E1', PondColour.blue),
      ('E2', PondColour.green),
      ('E3', PondColour.red),
    ]) {
      await PondRepository(
        db,
        session,
      ).create(PondInput(code: code, colour: colour, role: PondRole.growout));
    }
    await tester.pumpAndSettle();
    appContainer(tester).read(routerProvider).go('/more/paper');
    await tester.pumpAndSettle();
  }

  /// The PDF is built off the test clock (fonts, layout).
  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 50 && !done(); i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    await tester.pumpAndSettle();
  }

  appTest('printing sends the chosen ponds and weeks', (tester, db) async {
    await open(tester, db);
    expect(find.text('Semaine du 09/11/2026'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const ValueKey('paperPond-E2')));
    await tapAndSettle(tester, find.byKey(const ValueKey('paperWeeks-2')));
    await tapAndSettle(tester, find.text('Imprimer'));
    await waitFor(tester, () => printed.isNotEmpty);
    final (name, bytes) = printed.single;
    expect(name, 'fiches-2026-11-09.pdf');
    expect(pageCount(bytes), 4);
  }, overrides: overrides);

  appTest('share writes the file and opens the share sheet', (
    tester,
    db,
  ) async {
    await open(tester, db);
    await tapAndSettle(tester, find.byTooltip('Semaine suivante'));
    await tapAndSettle(tester, find.text('Partager le PDF'));
    await waitFor(tester, () => shared.isNotEmpty);
    expect(shared.single.path, endsWith('fiches-2026-11-16.pdf'));
  }, overrides: overrides);

  appTest('no pond ticked disables both buttons', (tester, db) async {
    await open(tester, db);
    for (final code in ['E1', 'E2', 'E3']) {
      await tapAndSettle(tester, find.byKey(ValueKey('paperPond-$code')));
    }
    for (final label in ['Imprimer', 'Partager le PDF']) {
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
      );
      expect(button.onPressed, isNull, reason: label);
    }
  }, overrides: overrides);

  appTest('the More tab lists Fiches papier for a member', (tester, db) async {
    appContainer(tester).read(routerProvider).go('/more');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Fiches papier'));
    await tapAndSettle(tester, find.text('Fiches papier'));
    expect(find.text('Imprimer'), findsOneWidget);
  }, overrides: overrides);
}
