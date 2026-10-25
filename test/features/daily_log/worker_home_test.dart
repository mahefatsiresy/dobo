import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/features/common/farm_today.dart';
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

  group('the next morning', () {
    var now = DateTime.utc(2026, 3, 2, 6); // 09:00 in Madagascar
    appTest('yesterday\'s ticks are gone', (tester, db) async {
      await twoPonds(tester, db);
      final session = (await SetupRepository(db).currentSession())!;
      final e1 = (await db.select(db.ponds).get())
          .singleWhere((p) => p.code == 'E1')
          .id;
      await DailyLogRepository(db, session).save(
        DailyLogInput(pondId: e1, date: DateTime(2026, 3, 2), feedGivenG: 4000),
      );
      await enterWorkerMode(tester);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
      expect(find.text('02/03/2026'), findsOneWidget);

      now = DateTime.utc(2026, 3, 3, 6);
      appContainer(tester).read(farmTodayProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.task_alt), findsNothing);
      expect(find.text('03/03/2026'), findsOneWidget);
    }, overrides: [clockProvider.overrideWithValue(() => now)]);
  });
}
