import 'dart:io';

import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/exports/csv.dart';
import 'package:dobo/features/reports/share_report.dart';
import 'package:dobo/features/sync/backup_actions.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';

void main() {
  final shared = <File>[];
  final overrides = [
    // Wednesday 11/11/2026, 09:00 in Madagascar.
    clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 11, 6)),
    reportSharerProvider.overrideWithValue((file) async => shared.add(file)),
    backupDirProvider.overrideWithValue(
      () async => Directory.systemTemp.createTemp('dobo-exports'),
    ),
  ];
  setUp(shared.clear);

  Future<void> farm(WidgetTester tester, AppDatabase db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final e1 = await ponds.create(pondInput('E1'));
    final e2 = await ponds.create(pondInput('E2'));
    final batches = BatchRepository(db, session);
    await batches.stockBatch(
      stockInput('L1', pondId: e1, date: DateTime(2026, 11, 1)),
    );
    await batches.stockBatch(
      stockInput('L2', pondId: e2, date: DateTime(2026, 11, 1)),
    );
    final logs = DailyLogRepository(db, session);
    for (var day = 2; day <= 4; day++) {
      await logs.save(
        DailyLogInput(
          pondId: e1,
          date: DateTime(2026, 11, day),
          feedGivenG: 2000,
        ),
      );
    }
    await logs.save(
      DailyLogInput(pondId: e2, date: DateTime(2026, 11, 2), feedGivenG: 900),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, [String query = '']) async {
    appContainer(tester).read(routerProvider).go('/more/exports$query');
    await tester.pumpAndSettle();
  }

  /// The export is built off the test clock (fonts, layout, files).
  Future<void> waitForShare(WidgetTester tester) async {
    for (var i = 0; i < 50 && shared.isEmpty; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    await tester.pumpAndSettle();
  }

  FilledButton button(WidgetTester tester, String label) =>
      tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
      );

  appTest('the register CSV of E1 is shared with its rows', (tester, db) async {
    await farm(tester, db);
    await open(tester);
    expect(find.text('13/10/2026'), findsOneWidget);
    expect(find.text('11/11/2026'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const ValueKey('exportPond')));
    await tapAndSettle(tester, find.text('E1').last);
    await tapAndSettle(tester, find.text('CSV'));
    await waitForShare(tester);
    expect(
      shared.single.path,
      endsWith('registre-Ambohidratrimo-2026-10-13-2026-11-11.csv'),
    );
    final rows = await tester.runAsync(
      () async => decodeCsv(await shared.single.readAsString()),
    );
    expect(rows!.first.first, 'Date');
    expect(rows, hasLength(5)); // header, stocking, 3 logs
    expect(rows.skip(1).every((r) => r[1].startsWith('E1')), isTrue);
  }, overrides: overrides);

  appTest('the weekly PDF is shared', (tester, db) async {
    await farm(tester, db);
    await open(tester);
    await tapAndSettle(tester, find.text('Suivi hebdomadaire (annexe B)'));
    await tapAndSettle(tester, find.text('PDF'));
    await waitForShare(tester);
    expect(
      shared.single.path,
      endsWith('suivi-hebdo-Ambohidratrimo-2026-09-21-2026-11-15.pdf'),
    );
    final bytes = await tester.runAsync(shared.single.readAsBytes);
    expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
  }, overrides: overrides);

  appTest('an end date before the start disables both buttons and says so', (
    tester,
    db,
  ) async {
    await open(tester, '?from=2026-11-10&to=2026-11-01');
    expect(
      find.text('La date de fin est avant la date de début.'),
      findsOneWidget,
    );
    expect(button(tester, 'PDF').onPressed, isNull);
    expect(button(tester, 'CSV').onPressed, isNull);
  }, overrides: overrides);

  appTest('switching to the weekly sheet sets 8 weeks back', (
    tester,
    db,
  ) async {
    await open(tester);
    await tapAndSettle(tester, find.text('Suivi hebdomadaire (annexe B)'));
    expect(find.text('23/09/2026'), findsOneWidget);
    expect(find.text('11/11/2026'), findsOneWidget);
  }, overrides: overrides);

  appTest('the More tab lists Exports', (tester, db) async {
    await open(tester);
    appContainer(tester).read(routerProvider).go('/more');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Exports'));
    await tapAndSettle(tester, find.text('Exports'));
    expect(find.text('CSV'), findsOneWidget);
  }, overrides: overrides);
}
