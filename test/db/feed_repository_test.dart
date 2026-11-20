import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/feed_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late FeedRepository feed;
  final today = DateTime(2026, 3, 20);

  setUp(() async {
    (db, session) = await setUpFarm();
    feed = FeedRepository(db, session);
  });
  tearDown(() => db.close());

  FeedDeliveryInput delivery({int kg = 25, Phase phase = Phase.growout}) =>
      FeedDeliveryInput(
        date: DateTime(2026, 3, 5),
        phase: phase,
        weightG: kg * 1000,
        manufacturedOn: DateTime(2026, 3, 1),
      );

  test('a delivery shows in stock', () async {
    await feed.deliver(delivery());
    final s = await feed.stock(today);
    expect((s.onHandG, s.lots.single.balanceG), (25000, 25000));
  });

  test('a discard lowers it', () async {
    final lot = await feed.deliver(delivery());
    await feed.discard(
      lot,
      weightG: 5000,
      reason: DiscardReason.mould,
      on: DateTime(2026, 3, 8),
    );
    expect((await feed.stock(today)).onHandG, 20000);
  });

  test('deleting a delivery removes its stock', () async {
    final lot = await feed.deliver(delivery());
    await feed.deleteDelivery(lot);
    final s = await feed.stock(today);
    expect(s.onHandG, 0);
    expect(s.lots, isEmpty);
  });

  test('correcting a delivery keeps its lot id for logs', () async {
    final lot = await feed.deliver(delivery());
    await feed.correctDelivery(lot, delivery(kg: 30));
    final s = await feed.stock(today);
    expect(s.lots.single.lot.id, lot);
    expect(s.onHandG, 30000);
  });

  test('a lot reads as its latest correction', () async {
    final lot = await feed.deliver(delivery());
    expect((await feed.delivery(lot))!.weightG, 25000);
    await feed.correctDelivery(lot, delivery(kg: 30));
    expect((await feed.delivery(lot))!.weightG, 30000);
    await feed.deleteDelivery(lot);
    expect(await feed.delivery(lot), isNull);
  });
}
