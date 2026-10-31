import 'package:dobo/domain/alerts/farm_alerts.dart';
import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/growth.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

/// A year of a 10-pond farm: one batch per pond, a log every day, a sample
/// every 14 days, a few deaths. Alerts and every pond's growth must stay
/// far below a frame budget on a desktop, so a low-end phone stays usable.
void main() {
  test(
    'a year of 10 ponds: alerts and growth fast enough for a low-end phone',
    () {
      final start = DateTime(2025, 3, 1);
      DateTime day(int n) =>
          farmDateToUtc(DateTime(start.year, start.month, start.day + n));
      final ponds = [for (var p = 0; p < 10; p++) 'p$p'];
      final facts = FarmFacts(
        stockings: [
          for (final p in ponds)
            StockingFact(
              batchId: 'b$p',
              pondId: p,
              count: 2000,
              avgWeightG: 10,
              date: day(0),
            ),
        ],
        samples: [
          for (final p in ponds)
            for (var n = 14; n < 365; n += 14)
              SampleFact(
                batchId: 'b$p',
                pondId: p,
                avgWeightG: 10 + n * 0.8,
                date: day(n),
              ),
        ],
        logs: [
          for (final p in ponds)
            for (var n = 1; n < 365; n++)
              LogFact(
                id: '$p-$n',
                pondId: p,
                date: day(n),
                feedG: 2000 + n * 10,
                deaths: n % 9 == 0 ? 2 : 0,
              ),
        ],
      );
      final sw = Stopwatch()..start();
      final alerts = farmAlerts(
        facts: facts,
        ponds: [
          for (final p in ponds)
            PondInfo(
              id: p,
              code: p,
              structure: StructureType.earth,
              surfaceM2: 500,
            ),
        ],
        batches: {
          for (final p in ponds)
            'b$p': BatchInfo(id: 'b$p', status: BatchStatus.active),
        },
        latestReadings: const {},
        now: day(365),
        config: DomainConfig.defaults,
      );
      for (final p in ponds) {
        weighPoints(facts, batchId: 'b$p', pondId: p);
        fcrPeriods(facts, batchId: 'b$p', pondId: p);
        batchSurvival(facts, 'b$p');
        dailyDeaths(facts, p, from: day(335), to: day(365));
      }
      sw.stop();
      expect(alerts, isNotEmpty);
      expect(sw.elapsedMilliseconds, lessThan(200));
    },
  );
}
