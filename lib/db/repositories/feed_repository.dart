import 'package:drift/drift.dart';

import '../../domain/config.dart';
import '../../domain/dates.dart';
import '../../domain/farm_facts.dart';
import '../../domain/feed_lots.dart';
import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../session.dart';
import 'facts_repository.dart';
import 'watch_tables.dart';

/// Feed received: a delivery is a lot (plan M7 Decision 4).
class FeedDeliveryInput {
  const FeedDeliveryInput({
    required this.date,
    required this.phase,
    required this.weightG,
    required this.manufacturedOn,
    this.pelletMm,
    this.proteinPct,
    this.supplier,
    this.label,
  });

  /// Delivery date, date only.
  final DateTime date;
  final Phase phase;
  final int weightG;

  /// Date only.
  final DateTime manufacturedOn;
  final double? pelletMm;
  final double? proteinPct;
  final String? supplier;
  final String? label;
}

/// Feed lots and stock (SPEC F11).
class FeedRepository {
  FeedRepository(this.db, this.session, {this.config = DomainConfig.defaults});

  final AppDatabase db;
  final Session session;
  final DomainConfig config;

  /// Records a delivery; returns its id, which is the lot id.
  Future<String> deliver(FeedDeliveryInput input) async {
    _checkWeight(input.weightG);
    return (await db.into(db.feedDeliveries).insertReturning(_delivery(input)))
        .id;
  }

  /// Corrections keep the first id as the lot id: logs point at it.
  Future<String> correctDelivery(String lotId, FeedDeliveryInput input) async {
    _checkWeight(input.weightG);
    return db.transaction(() async {
      final current = await _currentVersion(lotId);
      return db.supersede(db.feedDeliveries, current, _delivery(input));
    });
  }

  Future<void> deleteDelivery(String lotId) => db.transaction(() async {
    await db.tombstone(
      db.feedDeliveries,
      await _currentVersion(lotId),
      session,
    );
  });

  Future<String> discard(
    String lotId, {
    required int weightG,
    required DiscardReason reason,
    required DateTime on,
  }) async {
    _checkWeight(weightG);
    return (await db
            .into(db.feedDiscards)
            .insertReturning(
              FeedDiscardsCompanion.insert(
                associationId: session.associationId,
                enteredBy: session.userId,
                deviceId: session.deviceId,
                recordedAt: farmDateToUtc(on),
                lotId: lotId,
                weightG: weightG,
                reason: reason,
              ),
            ))
        .id;
  }

  Future<void> deleteDiscard(String id) =>
      db.tombstone(db.feedDiscards, id, session);

  /// Stock on [today], a date.
  Future<FeedStock> stock(DateTime today) async =>
      currentFeedStock(db, await currentFacts(db), today, config);

  Stream<FeedStock> watchStock(DateTime today) =>
      watchTables(db, feedTables(db), () => stock(today));

  /// The lot a new log of [pondId] on [day] draws from (Decision 5).
  Future<String?> defaultLotFor(String pondId, DateTime day) async {
    final facts = await currentFacts(db);
    final stock = await currentFeedStock(db, facts, day, config);
    return defaultFeedLot(
      stock: stock,
      pondPhase: pondPhase(placementsOf(facts, until: day), pondId, config),
    );
  }

  /// The current version of the lot whose first id is [lotId].
  Future<String> _currentVersion(String lotId) async {
    for (final d in await currentEvents(db, db.feedDeliveries).get()) {
      if ((await db.chainIds(db.feedDeliveries, d.id)).contains(lotId)) {
        return d.id;
      }
    }
    return lotId;
  }

  void _checkWeight(int g) {
    if (g <= 0) throw ArgumentError.value(g, 'weightG');
  }

  FeedDeliveriesCompanion _delivery(FeedDeliveryInput i) =>
      FeedDeliveriesCompanion.insert(
        associationId: session.associationId,
        enteredBy: session.userId,
        deviceId: session.deviceId,
        recordedAt: farmDateToUtc(i.date),
        siteId: session.siteId,
        phase: i.phase,
        weightG: i.weightG,
        manufacturedOn: farmDateToUtc(i.manufacturedOn),
        pelletMm: Value(i.pelletMm),
        proteinPct: Value(i.proteinPct),
        supplier: Value(i.supplier),
        label: Value(i.label),
      );
}

/// What feed stock is computed from.
Set<TableInfo<Table, Object?>> feedTables(AppDatabase db) => {
  db.feedDeliveries,
  db.feedDiscards,
  db.dailyLogs,
};

/// Feed stock on [today] from the current deliveries and discards and
/// [facts]' counted logs. A corrected delivery keeps its first id as the
/// lot id.
Future<FeedStock> currentFeedStock(
  AppDatabase db,
  FarmFacts facts,
  DateTime today,
  DomainConfig config,
) async {
  final lots = <FeedLotFact>[];
  for (final d in await currentEvents(db, db.feedDeliveries).get()) {
    final chain = await db.chainIds(db.feedDeliveries, d.id);
    lots.add(
      FeedLotFact(
        id: await _firstId(db, chain),
        phase: d.phase,
        weightG: d.weightG,
        manufacturedOn: d.manufacturedOn,
        deliveredOn: d.recordedAt,
        label: d.label,
      ),
    );
  }
  return feedStock(
    lots: lots,
    discards: [
      for (final d in await currentEvents(db, db.feedDiscards).get())
        FeedDiscardFact(lotId: d.lotId, weightG: d.weightG, date: d.recordedAt),
    ],
    countedLogs: countedLogs(facts),
    today: today,
    config: config,
  );
}

/// The id in [chain] that supersedes nothing.
Future<String> _firstId(AppDatabase db, Set<String> chain) async {
  if (chain.length == 1) return chain.single;
  final rows = await (db.select(
    db.feedDeliveries,
  )..where((d) => d.id.isIn(chain) & d.supersedesId.isNull())).get();
  return rows.single.id;
}
