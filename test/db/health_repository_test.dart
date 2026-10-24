import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/errors.dart';
import 'package:dobo/db/repositories/health_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late PondRepository ponds;
  late BatchRepository batches;
  late HealthRepository health;
  late String e1, e2, l1;

  setUp(() async {
    (db, session) = await setUpFarm();
    ponds = PondRepository(db, session);
    batches = BatchRepository(db, session);
    health = HealthRepository(db, session, visitId: 'v1');
    e1 = await ponds.create(pondInput('E1'));
    e2 = await ponds.create(pondInput('E2'));
    l1 = await batches.stockBatch(stockInput('L26-01', pondId: e1));
  });
  tearDown(() => db.close());

  test('isolating blocks fish leaving the pond', () async {
    await health.report(
      pondId: e1,
      signs: {WarningSign.rubbing},
      isolate: true,
      technicianCalled: true,
    );
    expect((await ponds.get(e1)).status, PondStatus.isolated);
    final event = await db.select(db.healthEvents).getSingle();
    expect(event.actions, {
      HealthAction.isolated,
      HealthAction.technicianCalled,
    });
    expect(event.signs, {WarningSign.rubbing});
    expect(event.visitId, 'v1');
    await expectLater(
      batches.transfer(moveInput(l1, from: e1, to: e2, count: 10)),
      throwsA(isA<PondIsolatedException>()),
    );
  });

  test('a report without isolation leaves the status alone', () async {
    await health.report(
      pondId: e1,
      signs: {WarningSign.noAppetite},
      isolate: false,
      technicianCalled: false,
    );
    expect((await ponds.get(e1)).status, isNot(PondStatus.isolated));
    expect((await db.select(db.healthEvents).getSingle()).actions, isEmpty);
  });

  test('release lifts isolation with its own event', () async {
    await health.report(
      pondId: e1,
      signs: const {},
      isolate: true,
      technicianCalled: false,
    );
    await health.release(e1);
    expect((await ponds.get(e1)).status, PondStatus.empty);
    final events = await health.watchForPond(e1).first;
    expect(events.first.actions, {HealthAction.released});
    expect(events, hasLength(2));
  });

  test('a treatment is recorded with its batch and adviser', () async {
    await health.addTreatment(
      TreatmentInput(
        pondId: e1,
        batchId: l1,
        date: DateTime(2026, 3, 5),
        product: 'Sel',
        dose: '3 kg',
        advisedBy: 'Dr Rabe',
      ),
    );
    final t = (await health.watchTreatments(e1).first).single;
    expect(
      (t.batchId, t.product, t.dose, t.advisedBy),
      (l1, 'Sel', '3 kg', 'Dr Rabe'),
    );
  });

  test('a treatment needs a product and a dose', () async {
    await expectLater(
      health.addTreatment(
        TreatmentInput(
          pondId: e1,
          date: DateTime(2026, 3, 5),
          product: ' ',
          dose: '3 kg',
        ),
      ),
      throwsArgumentError,
    );
    expect(await db.select(db.treatments).get(), isEmpty);
  });
}
