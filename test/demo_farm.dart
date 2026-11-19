import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/health_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/prep_repository.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';

/// The demo farm's "now": 15/03/2026, 09:00 in Madagascar.
final demoNow = DateTime.utc(2026, 3, 15, 6);

/// Pond ids of the demo farm, by code.
typedef DemoFarm = Map<String, String>;

/// A farm with one pond in each state the ponds list must show, for the
/// design goldens and the device screenshots (plan design step 1). Run the
/// app with `clockProvider` at [demoNow].
///
/// - E1: healthy, ~1 240 fish at 150 g, logged today, no alerts.
/// - E2: oxygen 2 mg/L read today (danger, stop feeding), sample overdue.
/// - E3: water read today, sample overdue (warning only).
/// - E4: isolated by a health event.
/// - E5: more deaths logged than fish (count to check).
/// - E6: harvest planned tomorrow (pre-harvest fast).
/// - P1: drained and dried, next step the treatment.
/// - P2: empty.
Future<DemoFarm> seedDemoFarm(AppDatabase db) async {
  final session = (await SetupRepository(db).currentSession())!;
  final ponds = PondRepository(db, session);
  final batches = BatchRepository(db, session);
  final readings = ReadingRepository(db, session);
  final logs = DailyLogRepository(db, session);
  final today = DateTime(2026, 3, 15);
  DateTime daysAgo(int n) => DateTime(2026, 3, 15 - n);

  final farm = <String, String>{};
  Future<String> pond(String code, PondColour colour) async =>
      farm[code] = await ponds.create(
        PondInput(
          code: code,
          colour: colour,
          role: PondRole.growout,
          lengthM: 25,
          widthM: 20,
        ),
      );
  Future<void> stock(
    String code, {
    required int days,
    int count = 1240,
    int avgWeightMg = 150000,
    DateTime? harvestOn,
  }) => batches.stockBatch(
    StockInput(
      code: 'L-$code',
      pondId: farm[code]!,
      date: daysAgo(days),
      count: count,
      avgWeightMg: avgWeightMg,
      plannedHarvestOn: harvestOn,
    ),
  );
  Future<void> water(String code, double oxygen) => readings.addWaterReading(
    WaterReadingInput(
      pondId: farm[code]!,
      at: demoNow.subtract(const Duration(hours: 2)),
      temperatureC: 28,
      ph: 7.2,
      oxygenMgL: oxygen,
      colour: WaterColour.lightGreen,
    ),
  );

  await pond('E1', PondColour.blue);
  await stock('E1', days: 10);
  await water('E1', 5);
  await logs.save(
    DailyLogInput(
      pondId: farm['E1']!,
      date: today,
      feedGivenG: 7400,
      leftover: Leftover.none,
    ),
  );

  await pond('E2', PondColour.yellow);
  await stock('E2', days: 20, count: 1500, avgWeightMg: 60000);
  await water('E2', 2);

  await pond('E3', PondColour.green);
  await stock('E3', days: 20, count: 1100, avgWeightMg: 90000);
  await water('E3', 5);

  await pond('E4', PondColour.red);
  await stock('E4', days: 10, count: 900, avgWeightMg: 40000);
  await HealthRepository(db, session).report(
    pondId: farm['E4']!,
    signs: const {},
    isolate: true,
    technicianCalled: true,
  );

  await pond('E5', PondColour.purple);
  await stock('E5', days: 10, count: 300, avgWeightMg: 20000);
  await logs.save(
    DailyLogInput(
      pondId: farm['E5']!,
      date: daysAgo(1),
      feedGivenG: 0,
      deaths: 500,
    ),
  );

  await pond('E6', PondColour.orange);
  await stock('E6', days: 10, harvestOn: DateTime(2026, 3, 16));

  final prep = PrepRepository(db, session);
  await pond('P1', PondColour.black);
  await prep.record(farm['P1']!, PrepStep.drain, on: daysAgo(8));
  await prep.record(farm['P1']!, PrepStep.dry, on: daysAgo(1));

  await pond('P2', PondColour.blue);
  return farm;
}
