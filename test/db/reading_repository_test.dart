import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late ReadingRepository readings;
  late String e1, l1;

  setUp(() async {
    (db, session) = await setUpFarm();
    readings = ReadingRepository(db, session, visitId: 'v1');
    e1 = await PondRepository(db, session).create(pondInput('E1'));
    l1 = await BatchRepository(
      db,
      session,
    ).stockBatch(stockInput('L26-01', pondId: e1));
  });
  tearDown(() => db.close());

  test('a sample sets the batch weight in its pond', () async {
    await readings.addSample(
      SampleInput(
        batchId: l1,
        pondId: e1,
        date: DateTime(2026, 3, 15),
        fishCount: 40,
        totalWeightG: 1248,
      ),
    );
    expect((await currentPlacements(db)).single.avgWeightG, 31.2);
    final s = await db.select(db.samples).getSingle();
    expect((s.visitId, s.enteredBy), ('v1', session.userId));
  });

  test('a sample of no fish or no weight is refused', () async {
    for (final (n, g) in [(0, 1000), (30, 0)]) {
      await expectLater(
        readings.addSample(
          SampleInput(
            batchId: l1,
            pondId: e1,
            date: DateTime(2026, 3, 15),
            fishCount: n,
            totalWeightG: g,
          ),
        ),
        throwsArgumentError,
      );
    }
    expect(await db.select(db.samples).get(), isEmpty);
  });

  test('a water reading needs at least one value', () async {
    await expectLater(
      readings.addWaterReading(
        WaterReadingInput(pondId: e1, at: DateTime.utc(2026, 3, 1, 6)),
      ),
      throwsArgumentError,
    );
    expect(await db.select(db.waterReadings).get(), isEmpty);
  });

  test('the latest water reading of a pond', () async {
    await readings.addWaterReading(
      WaterReadingInput(pondId: e1, at: DateTime.utc(2026, 3, 1, 6), ph: 7.0),
    );
    await readings.addWaterReading(
      WaterReadingInput(
        pondId: e1,
        at: DateTime.utc(2026, 3, 8, 6),
        ph: 7.5,
        oxygenMgL: 2.5,
        colour: WaterColour.darkGreen,
      ),
    );
    final latest = await readings.watchLatestWaterReading(e1).first;
    expect(
      (latest!.ph, latest.oxygenMgL, latest.colour),
      (7.5, 2.5, WaterColour.darkGreen),
    );
    expect(latest.recordedAt, DateTime.utc(2026, 3, 8, 6));
  });

  test('a corrected sample replaces the old weight', () async {
    final id = await readings.addSample(
      SampleInput(
        batchId: l1,
        pondId: e1,
        date: DateTime(2026, 3, 15),
        fishCount: 40,
        totalWeightG: 1248,
      ),
    );
    await readings.correctSample(
      id,
      SampleInput(
        batchId: l1,
        pondId: e1,
        date: DateTime(2026, 3, 15),
        fishCount: 40,
        totalWeightG: 1600,
      ),
    );
    expect((await currentPlacements(db)).single.avgWeightG, 40.0);
    expect(await readings.watchSamples(l1).first, hasLength(1));
  });

  test(
    'watchLatestWaterReadings keeps the newest current reading per pond',
    () async {
      final e2 = await PondRepository(db, session).create(pondInput('E2'));
      WaterReadingInput at(String pond, int day, double t) => WaterReadingInput(
        pondId: pond,
        at: DateTime.utc(2026, 3, day, 6),
        temperatureC: t,
      );
      await readings.addWaterReading(at(e1, 10, 27));
      final newest = await readings.addWaterReading(at(e1, 12, 28));
      await readings.addWaterReading(at(e2, 11, 29));
      var latest = await readings.watchLatestWaterReadings().first;
      expect(
        {for (final e in latest.entries) e.key: e.value.temperatureC},
        {e1: 28, e2: 29},
      );
      await readings.deleteWaterReading(newest);
      latest = await readings.watchLatestWaterReadings().first;
      expect(latest[e1]!.temperatureC, 27);
    },
  );

  test('watchWaterReadingsBetween keeps both ends and leaves out superseded '
      'and deleted readings', () async {
    WaterReadingInput at(DateTime t, double ph) =>
        WaterReadingInput(pondId: e1, at: t, ph: ph);
    // Farm days 9–10 March: 00:00 on the 9th to 23:59 on the 10th.
    await readings.addWaterReading(
      at(farmTimeToUtc(DateTime(2026, 3, 8), 23, 59), 1),
    );
    await readings.addWaterReading(
      at(farmTimeToUtc(DateTime(2026, 3, 9), 0, 0), 2),
    );
    final fixed = await readings.addWaterReading(
      at(farmTimeToUtc(DateTime(2026, 3, 9), 8, 0), 3),
    );
    await readings.correctWaterReading(
      fixed,
      at(farmTimeToUtc(DateTime(2026, 3, 9), 8, 0), 4),
    );
    final gone = await readings.addWaterReading(
      at(farmTimeToUtc(DateTime(2026, 3, 10), 9, 0), 5),
    );
    await readings.deleteWaterReading(gone);
    await readings.addWaterReading(
      at(farmTimeToUtc(DateTime(2026, 3, 10), 23, 59), 6),
    );
    await readings.addWaterReading(
      at(farmTimeToUtc(DateTime(2026, 3, 11), 0, 0), 7),
    );
    final rows = await readings
        .watchWaterReadingsBetween(DateTime(2026, 3, 9), DateTime(2026, 3, 10))
        .first;
    expect(rows.map((r) => r.ph), [2, 4, 6]);
  });
}
