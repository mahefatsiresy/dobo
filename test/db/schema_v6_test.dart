import 'package:dobo/db/database.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final at = DateTime.utc(2026, 3, 20, 9);

  test('a prep step keeps its step, product and dose', () async {
    await db
        .into(db.prepSteps)
        .insert(
          PrepStepsCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            recordedAt: at,
            pondId: 'p1',
            step: PrepStep.treat,
            product: const Value(PrepProduct.quicklime),
            doseG: const Value(45000),
          ),
        );
    final r = await db.select(db.prepSteps).getSingle();
    expect(
      (r.pondId, r.step, r.product, r.doseG, r.isTombstone),
      ('p1', PrepStep.treat, PrepProduct.quicklime, 45000, false),
    );
  });

  test('a feed delivery is a lot with its phase and manufacture date', () async {
    await db
        .into(db.feedDeliveries)
        .insert(
          FeedDeliveriesCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            recordedAt: at,
            siteId: 's1',
            phase: Phase.growout,
            weightG: 50000,
            manufacturedOn: DateTime.utc(2026, 1, 10, 21),
            pelletMm: const Value(3),
            proteinPct: const Value(25),
          ),
        );
    final r = await db.select(db.feedDeliveries).getSingle();
    expect(
      (r.phase, r.weightG, r.pelletMm, r.proteinPct, r.supplier, r.label),
      (Phase.growout, 50000, 3.0, 25.0, null, null),
    );
  });

  test('a feed discard names its lot and reason', () async {
    await db
        .into(db.feedDiscards)
        .insert(
          FeedDiscardsCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            recordedAt: at,
            lotId: 'l1',
            weightG: 5000,
            reason: DiscardReason.mould,
          ),
        );
    final r = await db.select(db.feedDiscards).getSingle();
    expect((r.lotId, r.weightG, r.reason), ('l1', 5000, DiscardReason.mould));
  });

  test('a harvest and its sale', () async {
    await db
        .into(db.harvests)
        .insert(
          HarvestsCompanion.insert(
            id: const Value('h1'),
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            recordedAt: at,
            batchId: 'b1',
            pondId: 'p1',
            count: 950,
            weightG: 240000,
            isFinal: true,
          ),
        );
    await db
        .into(db.sales)
        .insert(
          SalesCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            recordedAt: at,
            harvestId: 'h1',
            batchId: 'b1',
            customerId: 'c1',
            weightG: 200000,
            form: ProductForm.fresh,
          ),
        );
    final h = await db.select(db.harvests).getSingle();
    final s = await db.select(db.sales).getSingle();
    expect((h.count, h.weightG, h.isFinal), (950, 240000, true));
    expect(
      (s.harvestId, s.customerId, s.form, s.deliveryNote),
      ('h1', 'c1', ProductForm.fresh, null),
    );
  });

  test('a customer is a reference row, active by default', () async {
    await db
        .into(db.customers)
        .insert(
          CustomersCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            name: 'Marché Antsirabe',
            type: CustomerType.market,
          ),
        );
    final c = await db.select(db.customers).getSingle();
    expect((c.name, c.type, c.contact, c.archived), (
      'Marché Antsirabe',
      CustomerType.market,
      null,
      false,
    ));
  });
}
