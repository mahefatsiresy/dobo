import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/feed_repository.dart';
import 'package:dobo/db/repositories/health_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late Session session;
  late String e1;

  Future<void> stocked(
    WidgetTester tester,
    AppDatabase db, {
    int count = 1000,
    int avgWeightMg = 100000,
  }) async {
    session = (await SetupRepository(db).currentSession())!;
    e1 = await PondRepository(db, session).create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    await BatchRepository(db, session).stockBatch(
      StockInput(
        code: 'L26-01',
        pondId: e1,
        date: DateTime(2026, 1, 1),
        count: count,
        avgWeightMg: avgWeightMg,
      ),
    );
    await tester.pumpAndSettle();
  }

  DateTime yesterday() =>
      farmDate(DateTime.now().toUtc()).subtract(const Duration(days: 1));

  appTest('the suggested ration is shown large, adjusted by leftovers', (
    tester,
    db,
  ) async {
    await stocked(tester, db); // 1 000 fish at 100 g: growout, 4 % of 100 kg
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Journal du jour'));
    expect(find.text('≈ 4 kg'), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton));

    await DailyLogRepository(db, session).save(
      DailyLogInput(
        pondId: e1,
        date: yesterday(),
        feedGivenG: 4000,
        leftover: Leftover.lots,
      ),
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Journal du jour'));
    expect(find.text('≈ 3,4 kg'), findsOneWidget);
  });

  appTest('more deaths than fish: 0 and to check, no ration', (
    tester,
    db,
  ) async {
    await stocked(tester, db, count: 50);
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Journal du jour'));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Aliment donné'),
      '0,2',
    );
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Morts'),
      '500',
    );
    await tapAndSettle(tester, find.text('Enregistrer'));
    await tapAndSettle(tester, find.text('Étangs')); // back to the pond list
    expect(find.text('À vérifier'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Journal du jour'));
    expect(find.textContaining('≈'), findsNothing);
  });

  appTest('death signs only once there are deaths', (tester, db) async {
    await stocked(tester, db);
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Journal du jour'));
    expect(find.text('Aspect des morts'), findsNothing);
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Morts'),
      '3',
    );
    expect(find.text('Aspect des morts'), findsOneWidget);
  });

  appTest('an isolated pond says so on the log and the worker tile', (
    tester,
    db,
  ) async {
    await stocked(tester, db);
    await HealthRepository(db, session).report(
      pondId: e1,
      signs: const {},
      isolate: true,
      technicianCalled: false,
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Journal du jour'));
    expect(find.text('Étang isolé'), findsWidgets);
    await tapAndSettle(tester, find.byType(BackButton));
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Mode ouvrier'));
    expect(find.text('Dobo mitokana'), findsOneWidget);
  });

  appTest('correcting a transcribed day keeps whose sheet it was', (
    tester,
    db,
  ) async {
    await stocked(tester, db);
    await DailyLogRepository(db, session).save(
      DailyLogInput(
        pondId: e1,
        date: farmDate(DateTime.now().toUtc()),
        feedGivenG: 30000,
        observedBy: 'p-rakoto',
      ),
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Journal du jour'));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Aliment donné'),
      '3',
    );
    await tapAndSettle(tester, find.text('Enregistrer'));
    final current = await DailyLogRepository(
      db,
      session,
    ).forDay(e1, farmDate(DateTime.now().toUtc()));
    expect((current!.feedGivenG, current.observedBy), (3000, 'p-rakoto'));
  });

  appTest('a member sees and can change the stamped lot', (tester, db) async {
    await stocked(tester, db); // 100 g: growout
    final feed = FeedRepository(db, session);
    FeedDeliveryInput lot(Phase phase, String label) => FeedDeliveryInput(
      date: DateTime(2026, 1, 2),
      phase: phase,
      weightG: 25000,
      manufacturedOn: farmDate(DateTime.now().toUtc()),
      label: label,
    );
    await feed.deliver(lot(Phase.growout, 'Bleu'));
    final other = await feed.deliver(lot(Phase.finishing, 'Rouge'));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Journal du jour'));
    expect(find.text("Lot d'aliment"), findsOneWidget);
    expect(find.text('Le plus ancien (automatique)'), findsOneWidget);
    await enterAndSettle(
      tester,
      find.widgetWithText(TextFormField, 'Aliment donné'),
      '4',
    );
    await tapAndSettle(tester, find.text('Le plus ancien (automatique)'));
    await tapAndSettle(tester, find.textContaining('Rouge').last);
    await tapAndSettle(tester, find.text('Enregistrer'));
    final log = await db.select(db.dailyLogs).getSingle();
    expect(log.feedLotId, other);
  });
}
