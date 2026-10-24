import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  Future<void> twoPonds(WidgetTester tester, AppDatabase db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    await ponds.create(
      const PondInput(
        code: 'E2',
        colour: PondColour.green,
        role: PondRole.growout,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterWorkerMode(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Mode ouvrier'));
  }

  appTest('worker mode shows pond tiles in Malagasy', (tester, db) async {
    await twoPonds(tester, db);
    await enterWorkerMode(tester);
    expect(find.text('Androany'), findsOneWidget);
    expect(find.text('E1'), findsOneWidget);
    expect(find.text('E2'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  appTest('log a day, see the tick, reopen and save again', (tester, db) async {
    await twoPonds(tester, db);
    await enterWorkerMode(tester);
    await tapAndSettle(tester, find.text('E1'));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Sakafo nomena'),
      '4,2',
    );
    await tapAndSettle(tester, find.text('Misy sisa kely'));
    await tapAndSettle(tester, find.text('Tehirizo'));

    expect(find.text('Androany'), findsOneWidget);
    expect(find.byIcon(Icons.task_alt), findsOneWidget);
    final log = await db.select(db.dailyLogs).getSingle();
    expect(
      (log.feedGivenG, log.leftover, log.deaths),
      (4200, Leftover.some, 0),
    );

    await tapAndSettle(tester, find.text('E1'));
    expect(find.text('4,2'), findsOneWidget);
    final save = find.text('Tehirizo');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pumpAndSettle();
    final rows = await db.select(db.dailyLogs).get();
    expect(rows, hasLength(2));
    expect(rows.where((r) => r.supersedesId != null), hasLength(1));
  });

  appTest('feed is required', (tester, db) async {
    await twoPonds(tester, db);
    await enterWorkerMode(tester);
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Tehirizo'));
    expect(find.text('Ilaina'), findsOneWidget);
    expect(await db.select(db.dailyLogs).get(), isEmpty);
  });

  appTest('exit returns to More, in French', (tester, db) async {
    await twoPonds(tester, db);
    await enterWorkerMode(tester);
    await tapAndSettle(tester, find.byTooltip('Hiala'));
    expect(find.text('Mode ouvrier'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
