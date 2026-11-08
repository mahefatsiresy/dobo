import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/exports/register.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime d(int day) => farmDateToUtc(DateTime(2026, 3, day));
  final from = DateTime(2026, 3, 1);
  final to = DateTime(2026, 3, 31);

  StockingFact stock(String pond, int day, {String batch = 'b1'}) =>
      StockingFact(
        batchId: batch,
        pondId: pond,
        count: 1000,
        avgWeightG: 20,
        date: d(day),
      );
  LogFact log(String id, String pond, DateTime date, {int feedG = 1000}) =>
      LogFact(id: id, pondId: pond, date: date, feedG: feedG);

  String describe(RegisterRow r) => switch (r) {
    StockingRow() => 'stocking ${r.pondId}',
    TransferRow(:final toPondId) => 'transfer ${r.pondId}>$toPondId',
    LogRow(:final log) => 'log ${r.pondId} ${log.id}',
    HarvestRow() => 'harvest ${r.pondId}',
    SaleRow() => 'sale ${r.pondId}',
    TreatmentRow() => 'treatment ${r.pondId}',
    HealthRow() => 'health ${r.pondId}',
  };

  test('logs, stocking, transfer, harvest and sale come out in date then '
      'kind order', () {
    final facts = FarmFacts(
      stockings: [stock('e1', 2)],
      transfers: [
        TransferFact(
          batchId: 'b1',
          fromPondId: 'e1',
          toPondId: 'e2',
          count: 400,
          date: d(5),
        ),
      ],
      logs: [log('l5', 'e1', d(5)), log('l2', 'e1', d(2))],
      harvests: [
        HarvestFact(
          batchId: 'b1',
          pondId: 'e2',
          count: 400,
          weightG: 100000,
          isFinal: true,
          date: d(20),
        ),
      ],
    );
    final rows = productionRegister(
      facts: facts,
      sales: [
        SaleFact(
          date: d(20),
          batchId: 'b1',
          pondId: 'e2',
          weightG: 80000,
          customerId: 'c1',
          form: ProductForm.fresh,
        ),
      ],
      from: from,
      to: to,
    );
    expect(rows.map(describe), [
      'stocking e1',
      'log e1 l2',
      'transfer e1>e2',
      'log e1 l5',
      'harvest e2',
      'sale e2',
    ]);
  });

  test('two logs for one pond-day make one row, the newer', () {
    final rows = productionRegister(
      facts: FarmFacts(
        logs: [log('old', 'e1', d(3)), log('new', 'e1', d(3), feedG: 2000)],
      ),
      from: from,
      to: to,
    );
    expect(rows.map(describe), ['log e1 new']);
  });

  test('a log names the batches in its pond at the end of that day', () {
    final facts = FarmFacts(
      stockings: [stock('e1', 1)],
      transfers: [
        TransferFact(
          batchId: 'b1',
          fromPondId: 'e1',
          toPondId: 'e2',
          count: 1000,
          date: d(5),
        ),
      ],
      logs: [
        log('e1-4', 'e1', d(4)),
        log('e1-6', 'e1', d(6)),
        log('e2-6', 'e2', d(6)),
      ],
    );
    final batches = {
      for (final r in productionRegister(facts: facts, from: from, to: to))
        if (r is LogRow) r.log.id: r.batchIds,
    };
    expect(batches, {
      'e1-4': ['b1'],
      'e1-6': <String>[],
      'e2-6': ['b1'],
    });
  });

  test('the pond filter keeps a transfer for both its ponds', () {
    final facts = FarmFacts(
      stockings: [
        stock('e1', 1),
        stock('e3', 1, batch: 'b3'),
      ],
      transfers: [
        TransferFact(
          batchId: 'b1',
          fromPondId: 'e1',
          toPondId: 'e2',
          count: 400,
          date: d(5),
        ),
      ],
    );
    for (final pond in ['e1', 'e2']) {
      final rows = productionRegister(
        facts: facts,
        from: from,
        to: to,
        pondId: pond,
      );
      expect(rows.whereType<TransferRow>(), hasLength(1), reason: pond);
      expect(rows.any((r) => r.pondId == 'e3'), isFalse);
    }
  });

  test('from and to are both included, by farm day', () {
    final day = DateTime(2026, 3, 10);
    final rows = productionRegister(
      facts: FarmFacts(
        logs: [
          log('first', 'e1', farmTimeToUtc(DateTime(2026, 3, 9), 0, 30)),
          log('late', 'e1', farmTimeToUtc(day, 23, 30)),
          log('next', 'e1', farmTimeToUtc(DateTime(2026, 3, 11), 0, 30)),
          log('before', 'e1', farmTimeToUtc(DateTime(2026, 3, 8), 23, 30)),
        ],
      ),
      from: DateTime(2026, 3, 9),
      to: day,
    );
    expect(rows.map(describe), ['log e1 first', 'log e1 late']);
  });

  test('a treatment with no batch and a health event are rows of their '
      'pond', () {
    final rows = productionRegister(
      facts: FarmFacts(stockings: [stock('e1', 1)]),
      treatments: [
        ('e1', TreatmentLine(at: d(8), product: 'Sel', dose: '3 g/L')),
      ],
      health: [
        (
          'e1',
          HealthLine(
            at: d(7),
            signs: const {WarningSign.whiteSpots},
            actions: const {HealthAction.isolated},
          ),
        ),
      ],
      from: from,
      to: to,
    );
    expect(rows.map(describe), ['stocking e1', 'health e1', 'treatment e1']);
    expect(rows.whereType<TreatmentRow>().single.batchIds, ['b1']);
  });

  test('nothing in range is an empty list', () {
    expect(
      productionRegister(
        facts: FarmFacts(logs: [log('l', 'e1', d(1))]),
        from: DateTime(2026, 4, 1),
        to: DateTime(2026, 4, 30),
      ),
      isEmpty,
    );
  });
}
