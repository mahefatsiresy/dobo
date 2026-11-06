import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/prep_repository.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/alerts/alerts_screen.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/daily_log/worker_home_screen.dart';
import 'package:dobo/features/readings/sample_screen.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';

void main() {
  final now = DateTime.utc(2026, 3, 20, 6); // 09:00 in Madagascar
  final clock = clockProvider.overrideWithValue(() => now);

  /// A stocked pond whose sample is due; with [lowOxygen], a danger too.
  Future<String> pond(
    AppDatabase db,
    String code, {
    bool lowOxygen = false,
  }) async {
    final session = (await SetupRepository(db).currentSession())!;
    final id = await PondRepository(
      db,
      session,
    ).create(pondInput(code, lengthM: 25, widthM: 20));
    await BatchRepository(
      db,
      session,
    ).stockBatch(stockInput('L$code', pondId: id, date: DateTime(2026, 3, 1)));
    await ReadingRepository(db, session).addWaterReading(
      WaterReadingInput(
        pondId: id,
        at: now,
        temperatureC: 28,
        oxygenMgL: lowOxygen ? 2 : 5,
      ),
    );
    return id;
  }

  Future<void> openAlerts(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Alertes'),
      ),
    );
  }

  appTest('empty farm shows that nothing is to do', (tester, db) async {
    await openAlerts(tester);
    expect(find.text('Aucune alerte, rien à faire'), findsOneWidget);
  }, overrides: [clock]);

  appTest('danger alert listed above warning', (tester, db) async {
    await pond(db, 'E1', lowOxygen: true);
    await openAlerts(tester);
    final danger = find.textContaining('Oxygène dissous trop bas');
    final warning = find.textContaining('échantillonnage à faire');
    expect(danger, findsOneWidget);
    expect(warning, findsOneWidget);
    expect(
      tester.getTopLeft(danger).dy,
      lessThan(tester.getTopLeft(warning).dy),
    );
    expect(find.byIcon(Icons.error), findsOneWidget);
  }, overrides: [clock]);

  appTest('pond chip filters the list', (tester, db) async {
    await pond(db, 'E1');
    await pond(db, 'E2');
    await openAlerts(tester);
    expect(find.textContaining('Lot LE1'), findsOneWidget);
    expect(find.textContaining('Lot LE2'), findsOneWidget);
    await tapAndSettle(tester, find.widgetWithText(ChoiceChip, 'E2'));
    expect(find.textContaining('Lot LE1'), findsNothing);
    expect(find.textContaining('Lot LE2'), findsOneWidget);
    await tapAndSettle(tester, find.widgetWithText(ChoiceChip, 'Tous'));
    expect(find.textContaining('Lot LE1'), findsOneWidget);
  }, overrides: [clock]);

  appTest('tapping sample due opens the sample form, Back returns', (
    tester,
    db,
  ) async {
    await pond(db, 'E1');
    await openAlerts(tester);
    await tapAndSettle(tester, find.textContaining('échantillonnage à faire'));
    expect(find.byType(SampleScreen), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.byType(AlertsScreen), findsOneWidget);
  }, overrides: [clock]);

  appTest('Alerts tab badge counts danger alerts', (tester, db) async {
    await pond(db, 'E1', lowOxygen: true);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.widgetWithText(Badge, '1'),
      ),
      findsOneWidget,
    );
  }, overrides: [clock]);

  appTest(
    'a worker account never reaches the alerts',
    (tester, db) async {
      appContainer(tester).read(routerProvider).go('/alerts');
      await tester.pumpAndSettle();
      expect(find.byType(WorkerHomeScreen), findsOneWidget);
      expect(find.byType(AlertsScreen), findsNothing);
    },
    role: MemberRole.worker,
    overrides: [clock],
  );

  appTest("the prep alert opens the pond's checklist", (tester, db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final e2 = await PondRepository(db, session).create(pondInput('E2'));
    await PrepRepository(
      db,
      session,
    ).record(e2, PrepStep.drain, on: DateTime(2026, 3, 14));
    await openAlerts(tester);
    await tapAndSettle(tester, find.textContaining('fissures'));
    expect(find.text('Préparation E2'), findsOneWidget);
  }, overrides: [clock]);
}
