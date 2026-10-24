import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/ponds/pond_overview.dart';
import 'package:dobo/features/visit/visit_checklist.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures.dart';

void main() {
  const cfg = DomainConfig.defaults;
  final today = DateTime(2026, 3, 15);
  final batches = {'L1': batchRow('L1'), 'L2': batchRow('L2')};

  PondOverview overview(String id, List<String> batchIds) => buildPondOverview(
    pondRow(id),
    [for (final b in batchIds) placementOf(b, id, 500, 20)],
    batches,
    cfg,
  );

  VisitChecklist build({
    List<PondOverview>? ponds,
    List<String> readFor = const [],
    List<(String, String)> sampled = const [],
    Map<(String, String), DateTime>? last,
    List<(String?, ObservationCategory)> observed = const [],
  }) => buildChecklist(
    ponds:
        ponds ??
        [
          overview('E1', ['L1']),
          overview('E2', ['L2']),
        ],
    readingsThisVisit: [for (final p in readFor) readingRow(p)],
    samplesThisVisit: [for (final (b, p) in sampled) sampleRow(b, p)],
    observationsThisVisit: [
      for (final (p, c) in observed) observationRow(p, c),
    ],
    lastSampleOrStocking:
        last ??
        {
          ('L1', 'E1'): DateTime(2026, 3, 1),
          ('L2', 'E2'): DateTime(2026, 3, 10),
        },
    today: today,
    config: cfg,
  );

  test('stocked ponds are due for water until read in this visit', () {
    final c = build(readFor: ['E1']);
    expect(c.waterDue.map((p) => p.code), ['E2']);
  });

  test('an empty pond is not due for water', () {
    final c = build(
      ponds: [
        overview('E1', ['L1']),
        overview('E3', []),
      ],
    );
    expect(c.waterDue.map((p) => p.code), ['E1']);
  });

  test('a batch is due for a sample after 14 days, not once sampled', () {
    expect(build().samplesDue.map((s) => (s.$1.id, s.$2.id)), [('L1', 'E1')]);
    expect(build(sampled: [('L1', 'E1')]).samplesDue, isEmpty);
  });

  test('a pond is due for conditions until all five are checked', () {
    const five = [
      ObservationCategory.dike,
      ObservationCategory.inletScreen,
      ObservationCategory.predatorNets,
      ObservationCategory.fence,
      ObservationCategory.grass,
    ];
    final c = build(observed: [for (final k in five) ('E1', k)]);
    expect(c.conditionsDue.map((p) => p.code), ['E2']);
    final partial = build(observed: [('E1', ObservationCategory.dike)]);
    expect(partial.conditionsDue.map((p) => p.code), ['E1', 'E2']);
  });
}
