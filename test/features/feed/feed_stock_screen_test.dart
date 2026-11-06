import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/feed_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';

void main() {
  final now = DateTime.utc(2026, 3, 20, 6); // 09:00 in Madagascar
  final clock = clockProvider.overrideWithValue(() => now);

  Future<FeedRepository> feed(AppDatabase db) async =>
      FeedRepository(db, (await SetupRepository(db).currentSession())!);

  Future<String> lot(AppDatabase db, {int kg = 25, DateTime? made}) async =>
      (await feed(db)).deliver(
        FeedDeliveryInput(
          date: DateTime(2026, 3, 15),
          phase: Phase.growout,
          weightG: kg * 1000,
          manufacturedOn: made ?? DateTime(2026, 3, 1),
          label: 'Sacs bleus',
        ),
      );

  Future<void> openStock(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Aliment'));
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  appTest('a 25 kg delivery shows 25 kg on hand', (tester, db) async {
    await openStock(tester);
    expect(find.text('Aucune livraison enregistrée'), findsOneWidget);
    await tapAndSettle(tester, find.text('Livraison'));
    await tapAndSettle(tester, find.text('Grossissement'));
    await enterAndSettle(tester, field('Poids livré'), '25');
    await tapAndSettle(tester, find.text('Date de fabrication'));
    await tapAndSettle(tester, find.text('OK'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('25 kg'), findsWidgets);
    final d = await db.select(db.feedDeliveries).getSingle();
    expect((d.phase, d.weightG), (Phase.growout, 25000));
  }, overrides: [clock]);

  appTest('a delivery needs its manufacture date', (tester, db) async {
    await openStock(tester);
    await tapAndSettle(tester, find.text('Livraison'));
    await tapAndSettle(tester, find.text('Grossissement'));
    await enterAndSettle(tester, field('Poids livré'), '25');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Obligatoire'), findsOneWidget);
    expect(await db.select(db.feedDeliveries).get(), isEmpty);
  }, overrides: [clock]);

  appTest('a 61-day lot shows the old badge', (tester, db) async {
    await lot(db, made: DateTime(2026, 1, 18));
    await openStock(tester);
    expect(find.text('Fabriqué le 18/01/2026 · 61 jours'), findsOneWidget);
    expect(find.text('À utiliser en priorité'), findsOneWidget);
  }, overrides: [clock]);

  appTest('discarding 5 kg leaves 20 kg', (tester, db) async {
    final id = await lot(db);
    await openStock(tester);
    await tapAndSettle(tester, find.byKey(ValueKey('discard-$id')));
    await enterAndSettle(tester, field('Poids jeté'), '5');
    await tapAndSettle(tester, find.text('Moisi'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('20 kg'), findsWidgets);
    final d = await db.select(db.feedDiscards).getSingle();
    expect((d.lotId, d.weightG, d.reason), (id, 5000, DiscardReason.mould));
  }, overrides: [clock]);

  appTest('more fed than delivered shows the overdrawn line', (
    tester,
    db,
  ) async {
    final id = await lot(db, kg: 5);
    final session = (await SetupRepository(db).currentSession())!;
    final e1 = await PondRepository(db, session).create(pondInput('E1'));
    await DailyLogRepository(db, session).save(
      DailyLogInput(
        pondId: e1,
        date: DateTime(2026, 3, 16),
        feedGivenG: 8000,
        feedLotId: id,
      ),
    );
    await openStock(tester);
    expect(find.text("Plus d'aliment donné que livré : 3 kg"), findsOneWidget);
  }, overrides: [clock]);

  appTest('the feed-age alert opens the stock', (tester, db) async {
    await lot(db, made: DateTime(2026, 1, 1));
    await tester.pumpAndSettle();
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Alertes'),
      ),
    );
    await tapAndSettle(tester, find.textContaining('vieillit'));
    expect(find.text("Stock d'aliment"), findsOneWidget);
  }, overrides: [clock]);
}
