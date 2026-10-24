import 'package:dobo/db/database.dart';
import 'package:dobo/db/events.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  const session = Session(
      associationId: 'a1', userId: 'u2', deviceId: 'd2', siteId: 's1');

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  StockingsCompanion stocking(int count, {String? id, String? supersedes}) =>
      StockingsCompanion.insert(
        id: id == null ? const Value.absent() : Value(id),
        associationId: 'a1',
        enteredBy: 'u1',
        deviceId: 'd1',
        recordedAt: DateTime.utc(2026, 3, 1, 9),
        batchId: 'b1',
        pondId: 'p1',
        count: count,
        avgWeightMg: 12500,
        supersedesId: Value(supersedes),
      );

  Future<String> insert(int count) async {
    final c = stocking(count);
    await db.into(db.stockings).insert(c);
    return (await (db.select(db.stockings)
              ..where((s) => s.count.equals(count)))
            .getSingle())
        .id;
  }

  Future<Set<int>> currentCounts() async {
    final rows = await (db.select(db.stockings)
          ..where((_) => isCurrentEvent(db.stockings)))
        .get();
    return {for (final r in rows) r.count};
  }

  test('a correction replaces the original', () async {
    final a = await insert(1000);
    await db.supersede(db.stockings, a, stocking(900));
    expect(await currentCounts(), {900});
  });

  test('a correction of a correction leaves only the last', () async {
    final a = await insert(1000);
    final b = await db.supersede(db.stockings, a, stocking(900));
    await db.supersede(db.stockings, b, stocking(950));
    expect(await currentCounts(), {950});
  });

  test('a tombstone hides the record and itself', () async {
    final a = await insert(1000);
    final t = await db.tombstone(db.stockings, a, session);
    expect(await currentCounts(), isEmpty);
    final row = await (db.select(db.stockings)
          ..where((s) => s.id.equals(t)))
        .getSingle();
    expect((row.isTombstone, row.supersedesId, row.count),
        (true, a, 1000));
    expect((row.enteredBy, row.deviceId, row.syncState),
        ('u2', 'd2', SyncState.pending));
  });

  test('deleting a correction does not bring back the original', () async {
    final a = await insert(1000);
    final b = await db.supersede(db.stockings, a, stocking(900));
    await db.tombstone(db.stockings, b, session);
    expect(await currentCounts(), isEmpty);
  });

  test('two corrections of the same record from two phones are both kept',
      () async {
    final a = await insert(1000);
    await db.supersede(db.stockings, a, stocking(900));
    await db.supersede(db.stockings, a, stocking(950));
    expect(await currentCounts(), {900, 950});
  });

  test("tables do not see each other's supersedes", () async {
    final a = await insert(1000);
    await db.into(db.transfers).insert(TransfersCompanion.insert(
          associationId: 'a1',
          enteredBy: 'u1',
          deviceId: 'd1',
          recordedAt: DateTime.utc(2026, 3, 2, 9),
          batchId: 'b1',
          fromPondId: 'p1',
          toPondId: 'p2',
          count: 10,
          supersedesId: Value(a),
        ));
    expect(await currentCounts(), {1000});
  });

  test('supersede stores the link even if the replacement omits it',
      () async {
    final a = await insert(1000);
    final b = await db.supersede(db.stockings, a, stocking(900));
    final row = await (db.select(db.stockings)
          ..where((s) => s.id.equals(b)))
        .getSingle();
    expect((row.supersedesId, row.isTombstone), (a, false));
  });
}
