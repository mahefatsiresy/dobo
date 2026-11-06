import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/fcr.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/domain/trace.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime day(int d) => DateTime(2026, 3, d);

  StockingFact stock(String b, int count, double g) => StockingFact(
    batchId: b,
    pondId: 'p1',
    count: count,
    avgWeightG: g,
    date: day(1),
  );

  /// [kg] of feed in p1, one log a day from the 2nd to the 29th.
  List<LogFact> feed(int kg) => [
    for (var d = 2; d <= 29; d++)
      LogFact(
        id: 'f$d',
        pondId: 'p1',
        date: day(d),
        feedG: d == 29 ? kg * 1000 - 27 * (kg * 1000 ~/ 28) : kg * 1000 ~/ 28,
      ),
  ];

  HarvestFact harvest(int count, int kg, {bool isFinal = true}) => HarvestFact(
    batchId: 'b1',
    pondId: 'p1',
    count: count,
    weightG: kg * 1000,
    isFinal: isFinal,
    date: day(30),
  );

  test('cycle FCR of a closed batch', () {
    final f = FarmFacts(
      stockings: [stock('b1', 1000, 20)],
      logs: feed(400),
      harvests: [harvest(950, 250)],
    );
    final t = batchTrace(f, 'b1', status: BatchStatus.closed);
    expect((t.stockedCount, t.stockedWeightG), (1000, 20000));
    expect((t.harvestedCount, t.harvestedWeightG), (950, 250000));
    expect(t.batchFeedG, 400000);
    expect((t.cycleFcr! as FcrValue).value, closeTo(400 / 230, 1e-9));
  });

  test('an open batch has no cycle FCR', () {
    final f = FarmFacts(
      stockings: [stock('b1', 1000, 20)],
      logs: feed(400),
      harvests: [harvest(300, 75, isFinal: false)],
    );
    final t = batchTrace(f, 'b1', status: BatchStatus.harvesting);
    expect((t.cycleFcr, t.live, t.harvestedCount), (null, 700, 300));
  });

  test('feed in a pond shared with another batch is split by biomass', () {
    final f = FarmFacts(
      stockings: [stock('b1', 1000, 20), stock('b2', 1000, 60)],
      logs: [LogFact(id: 'f', pondId: 'p1', date: day(2), feedG: 8000)],
    );
    expect(batchTrace(f, 'b1', status: BatchStatus.active).batchFeedG, 2000);
    expect(batchTrace(f, 'b2', status: BatchStatus.active).batchFeedG, 6000);
  });

  test('unaccounted fish are reported', () {
    final f = FarmFacts(
      stockings: [stock('b1', 1000, 20)],
      harvests: [harvest(900, 225)],
    );
    final t = batchTrace(f, 'b1', status: BatchStatus.closed);
    expect((t.unaccounted, t.live), (100, 0));
    expect(t.survival, closeTo(0.9, 1e-9));
  });

  test('a batch with nothing harvested yet still reports stocked and live', () {
    final f = FarmFacts(stockings: [stock('b1', 1000, 20)]);
    final t = batchTrace(f, 'b1', status: BatchStatus.active);
    expect(
      (t.stockedCount, t.live, t.harvestedCount, t.unaccounted),
      (1000, 1000, 0, 0),
    );
    expect((t.batchFeedG, t.cycleFcr), (0, null));
  });

  group('treatments on the sheet', () {
    final f = FarmFacts(
      stockings: [stock('b1', 1000, 20)],
      transfers: [
        TransferFact(
          batchId: 'b1',
          fromPondId: 'p1',
          toPondId: 'p2',
          count: 1000,
          date: day(10),
        ),
      ],
    );

    test('a treatment naming the batch counts wherever it was given', () {
      expect(
        treatmentConcernsBatch(
          f,
          'b1',
          treatmentBatchId: 'b1',
          pondId: 'p9',
          date: day(3),
        ),
        isTrue,
      );
      expect(
        treatmentConcernsBatch(
          f,
          'b1',
          treatmentBatchId: 'b2',
          pondId: 'p1',
          date: day(3),
        ),
        isFalse,
      );
    });

    test('a treatment with no batch counts for the pond the batch was in '
        'that day', () {
      bool at(String pond, int d) => treatmentConcernsBatch(
        f,
        'b1',
        treatmentBatchId: null,
        pondId: pond,
        date: day(d),
      );
      expect((at('p1', 5), at('p2', 5)), (true, false));
      expect((at('p1', 12), at('p2', 12)), (false, true));
    });
  });
}
