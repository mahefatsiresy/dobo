import 'package:dobo/domain/occupancy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final d1 = DateTime(2026, 3, 1), d2 = DateTime(2026, 3, 20);

  Placement at(List<Placement> ps, String b, String p) =>
      ps.singleWhere((x) => x.batchId == b && x.pondId == p);

  StockingFact stock(
    String b,
    String p,
    int count,
    double g, [
    DateTime? date,
  ]) => StockingFact(
    batchId: b,
    pondId: p,
    count: count,
    avgWeightG: g,
    date: date ?? d1,
  );

  TransferFact move(
    String b,
    String from,
    String to,
    int count, {
    double? g,
    DateTime? date,
  }) => TransferFact(
    batchId: b,
    fromPondId: from,
    toPondId: to,
    count: count,
    avgWeightG: g,
    date: date ?? d2,
  );

  test('a move splits the batch between ponds', () {
    final ps = placements(
      stockings: [stock('L1', 'E1', 1000, 12.5)],
      transfers: [move('L1', 'E1', 'E2', 300, g: 30)],
    );
    expect(at(ps, 'L1', 'E1').live.count, 700);
    expect(at(ps, 'L1', 'E2').live.count, 300);
    expect(at(ps, 'L1', 'E1').avgWeightG, 12.5);
    expect(at(ps, 'L1', 'E2').avgWeightG, 30.0);
    expect(ps, hasLength(2));
  });

  test('a move without weight carries the source weight', () {
    final ps = placements(
      stockings: [stock('L1', 'E1', 1000, 12.5)],
      transfers: [move('L1', 'E1', 'E2', 300)],
    );
    expect(at(ps, 'L1', 'E2').avgWeightG, 12.5);
  });

  test('facts are applied in date order, whatever the list order', () {
    final ps = placements(
      stockings: [stock('L1', 'E1', 1000, 12.5)],
      transfers: [
        move('L1', 'E2', 'E3', 100, date: DateTime(2026, 4, 1)),
        move('L1', 'E1', 'E2', 300, g: 30, date: DateTime(2026, 3, 20)),
      ],
    );
    expect(at(ps, 'L1', 'E3').avgWeightG, 30.0);
    expect(at(ps, 'L1', 'E2').live.count, 200);
  });

  test('a stocking and a move on the same day: stocking first', () {
    final ps = placements(
      stockings: [stock('L1', 'E1', 1000, 12.5, d2)],
      transfers: [move('L1', 'E1', 'E2', 300, date: d2)],
    );
    expect(at(ps, 'L1', 'E2').avgWeightG, 12.5);
  });

  test('a stocking corrected below what was moved out is inconsistent', () {
    final ps = placements(
      stockings: [stock('L1', 'E1', 500, 12.5)],
      transfers: [move('L1', 'E1', 'E2', 800)],
    );
    expect(
      (at(ps, 'L1', 'E1').live.count, at(ps, 'L1', 'E1').live.inconsistent),
      (0, true),
    );
    expect(at(ps, 'L1', 'E2').live.count, 800);
  });

  test('two batches in one pond stay separate', () {
    final ps = placements(
      stockings: [stock('L1', 'E1', 1000, 12.5), stock('L2', 'E1', 400, 20)],
      transfers: const [],
    );
    expect(at(ps, 'L1', 'E1').live.count, 1000);
    expect(at(ps, 'L2', 'E1').avgWeightG, 20.0);
  });

  test('a move into a pond with no weight yet and no source weight', () {
    final ps = placements(
      stockings: const [],
      transfers: [move('L1', 'E1', 'E2', 10)],
    );
    expect(at(ps, 'L1', 'E2').avgWeightG, isNull);
    expect(at(ps, 'L1', 'E1').live.inconsistent, isTrue);
  });

  test('no facts, no placements', () {
    expect(placements(stockings: const [], transfers: const []), isEmpty);
  });

  group('deaths and samples', () {
    final d1 = DateTime(2026, 3, 1),
        d2 = DateTime(2026, 3, 2),
        d3 = DateTime(2026, 3, 15);

    test('deaths reduce the count', () {
      final ps = placements(
        stockings: [stock('L1', 'E1', 1000, 12.5, d1)],
        transfers: const [],
        deaths: [DeathFact(pondId: 'E1', count: 30, date: d2)],
      );
      expect(at(ps, 'L1', 'E1').live.count, 970);
    });

    test('deaths are shared in proportion, remainder to the largest', () {
      final ps = placements(
        stockings: [
          stock('L1', 'E1', 600, 12.5, d1),
          stock('L2', 'E1', 300, 20, d1),
        ],
        transfers: const [],
        deaths: [DeathFact(pondId: 'E1', count: 10, date: d2)],
      );
      expect(
        (at(ps, 'L1', 'E1').live.count, at(ps, 'L2', 'E1').live.count),
        (593, 297),
      );
    });

    test('more deaths than fish is inconsistent, never negative', () {
      final ps = placements(
        stockings: [stock('L1', 'E1', 50, 12.5, d1)],
        transfers: const [],
        deaths: [DeathFact(pondId: 'E1', count: 500, date: d2)],
      );
      expect(
        (at(ps, 'L1', 'E1').live.count, at(ps, 'L1', 'E1').live.inconsistent),
        (0, true),
      );
    });

    test('deaths in an emptied pond go to the batch that was there', () {
      final ps = placements(
        stockings: [stock('L1', 'E1', 100, 12.5, d1)],
        transfers: [move('L1', 'E1', 'E2', 100, date: d2)],
        deaths: [DeathFact(pondId: 'E1', count: 2, date: d3)],
      );
      expect(at(ps, 'L1', 'E1').live.inconsistent, isTrue);
      expect(at(ps, 'L1', 'E2').live.count, 100);
    });

    test('deaths before the pond ever held fish are dropped', () {
      final ps = placements(
        stockings: [stock('L1', 'E1', 100, 12.5, d2)],
        transfers: const [],
        deaths: [DeathFact(pondId: 'E1', count: 5, date: d1)],
      );
      expect(at(ps, 'L1', 'E1').live.count, 100);
      expect(at(ps, 'L1', 'E1').live.inconsistent, isFalse);
    });

    test('a sample sets the weight of its batch in its pond', () {
      final ps = placements(
        stockings: [stock('L1', 'E1', 1000, 12.5, d1)],
        transfers: [move('L1', 'E1', 'E2', 100, date: d2)],
        samples: [
          SampleFact(batchId: 'L1', pondId: 'E1', avgWeightG: 31.2, date: d3),
        ],
      );
      expect(at(ps, 'L1', 'E1').avgWeightG, 31.2);
      expect(at(ps, 'L1', 'E2').avgWeightG, 12.5);
    });

    test('a later move without weight carries the sampled weight', () {
      final ps = placements(
        stockings: [stock('L1', 'E1', 1000, 12.5, d1)],
        transfers: [move('L1', 'E1', 'E2', 100, date: DateTime(2026, 3, 20))],
        samples: [
          SampleFact(batchId: 'L1', pondId: 'E1', avgWeightG: 31.2, date: d3),
        ],
      );
      expect(at(ps, 'L1', 'E2').avgWeightG, 31.2);
    });
  });
}
