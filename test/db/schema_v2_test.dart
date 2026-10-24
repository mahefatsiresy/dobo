import 'package:dobo/db/database.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Pond> insertPond(String code) async {
    await db
        .into(db.ponds)
        .insert(
          PondsCompanion.insert(
            associationId: 'a1',
            enteredBy: 'u1',
            deviceId: 'd1',
            siteId: 's1',
            code: code,
            colour: PondColour.blue,
            role: PondRole.growout,
          ),
        );
    return (db.select(
      db.ponds,
    )..where((p) => p.code.equals(code))).get().then((rows) => rows.last);
  }

  test('event rows default to current, not tombstoned', () async {
    final pond = await insertPond('E1');
    await db
        .into(db.batches)
        .insert(
          BatchesCompanion.insert(
            id: const Value('b1'),
            associationId: 'a1',
            enteredBy: 'u1',
            deviceId: 'd1',
            siteId: 's1',
            code: 'L26-01',
            status: BatchStatus.active,
          ),
        );
    await db
        .into(db.stockings)
        .insert(
          StockingsCompanion.insert(
            associationId: 'a1',
            enteredBy: 'u1',
            deviceId: 'd1',
            recordedAt: DateTime.utc(2026, 3, 1, 9),
            batchId: 'b1',
            pondId: pond.id,
            count: 1000,
            avgWeightMg: 12500,
          ),
        );
    final stocking = await db.select(db.stockings).getSingle();
    expect(stocking.isTombstone, isFalse);
    expect(stocking.supersedesId, isNull);
    expect(stocking.syncState, SyncState.pending);
  });

  test('pond defaults: earth, empty, not archived', () async {
    final pond = await insertPond('E1');
    expect(
      (pond.structure, pond.status, pond.archived),
      (StructureType.earth, PondStatus.empty, false),
    );
  });

  test('two ponds may share a code at database level', () async {
    await insertPond('E1');
    await insertPond('E1');
    expect(await db.select(db.ponds).get(), hasLength(2));
  });
}
