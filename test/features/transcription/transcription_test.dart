import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/person_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late String e1, rakoto;

  Future<void> openWeek(WidgetTester tester, AppDatabase db) async {
    final session = (await SetupRepository(db).currentSession())!;
    e1 = await PondRepository(db, session).create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    rakoto = await PersonRepository(db, session).create(name: 'Rakoto');
    await DailyLogRepository(db, session).save(
      DailyLogInput(pondId: e1, date: DateTime(2026, 3, 30), feedGivenG: 2500),
    );
    await tester.pumpAndSettle();
    appContainer(tester)
        .read(routerProvider)
        .go('/more/transcription?week=2026-04-01');
    await tester.pumpAndSettle();
  }

  Finder cell(String kind, String day) =>
      find.byKey(ValueKey('$kind-$e1-$day'));

  appTest('a paper sheet becomes daily logs on the right days', (
    tester,
    db,
  ) async {
    await openWeek(tester, db);
    expect(find.text('Semaine du 30/03/2026'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const ValueKey('sheetOf')));
    await tapAndSettle(tester, find.text('Rakoto').last);
    await enterAndSettle(tester, cell('kg', '2026-03-31'), '3');
    await enterAndSettle(tester, cell('deaths', '2026-03-31'), '2');
    await tapAndSettle(tester, find.text('Enregistrer'));

    final logs = await db.select(db.dailyLogs).get();
    expect(logs, hasLength(2));
    final added = logs.singleWhere((l) => l.observedBy != null);
    expect(farmDate(added.recordedAt), DateTime(2026, 3, 31));
    expect(
      (added.feedGivenG, added.deaths, added.observedBy),
      (3000, 2, rakoto),
    );
  });

  appTest('a day already logged shows greyed and is not written again', (
    tester,
    db,
  ) async {
    await openWeek(tester, db);
    expect(cell('kg', '2026-03-30'), findsNothing);
    expect(find.text('2,5 kg'), findsOneWidget);
  });

  appTest('a sheet needs whose it is', (tester, db) async {
    await openWeek(tester, db);
    await enterAndSettle(tester, cell('kg', '2026-04-01'), '3');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Obligatoire'), findsOneWidget);
    expect(await db.select(db.dailyLogs).get(), hasLength(1));
  });

  appTest('deaths without feed are refused', (tester, db) async {
    await openWeek(tester, db);
    await tapAndSettle(tester, find.byKey(const ValueKey('sheetOf')));
    await tapAndSettle(tester, find.text('Rakoto').last);
    await enterAndSettle(tester, cell('deaths', '2026-04-02'), '1');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.textContaining("Indiquez l'aliment"), findsOneWidget);
    expect(await db.select(db.dailyLogs).get(), hasLength(1));
  });

  appTest('cells typed in two weeks are all saved', (tester, db) async {
    await openWeek(tester, db);
    await tapAndSettle(tester, find.byKey(const ValueKey('sheetOf')));
    await tapAndSettle(tester, find.text('Rakoto').last);
    await enterAndSettle(tester, cell('kg', '2026-03-31'), '3');
    await tapAndSettle(tester, find.byTooltip('Semaine suivante'));
    await enterAndSettle(tester, cell('kg', '2026-04-07'), '4');
    await tapAndSettle(tester, find.text('Enregistrer'));
    final days = {
      for (final l in await db.select(db.dailyLogs).get())
        farmDate(l.recordedAt): l.feedGivenG,
    };
    expect(days[DateTime(2026, 3, 31)], 3000);
    expect(days[DateTime(2026, 4, 7)], 4000);
  });
}
