import 'package:dobo/domain/config.dart';
import 'package:drift/drift.dart' show Value;
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
    batches: batches,
    lastSampleOrStocking:
        last ??
        {
          ('L1', 'E1'): DateTime(2026, 3, 1),
          ('L2', 'E2'): DateTime(2026, 3, 10),
        },
    today: today,
    config: cfg,
  );

  const five = [
    ObservationCategory.dike,
    ObservationCategory.inletScreen,
    ObservationCategory.predatorNets,
    ObservationCategory.fence,
    ObservationCategory.grass,
  ];

  PondVisit pondOf(VisitChecklist c, String code) =>
      c.ponds.singleWhere((p) => p.overview.pond.code == code);

  List<Type> kinds(PondVisit p) => [for (final c in p.checks) c.runtimeType];

  test('a stocked pond gets water, its due sample and the inspection', () {
    final c = build(
      ponds: [
        overview('E1', ['L1']),
        overview('E3', []),
      ],
    );
    expect(kinds(pondOf(c, 'E1')), [WaterCheck, SampleCheck, InspectionCheck]);
    expect((pondOf(c, 'E1').checks[1] as SampleCheck).batch.id, 'L1');
    expect(kinds(pondOf(c, 'E3')), [InspectionCheck]);
  });

  test('a pond with two due batches samples them in batch code order', () {
    final c = build(
      ponds: [
        overview('E1', ['L2', 'L1']),
      ],
      last: {
        ('L1', 'E1'): DateTime(2026, 3, 1),
        ('L2', 'E1'): DateTime(2026, 3, 1),
      },
    );
    expect(
      [
        for (final k in pondOf(c, 'E1').checks)
          if (k is SampleCheck) k.batch.code,
      ],
      ['L1', 'L2'],
    );
  });

  test('a reading in this visit makes the water check done', () {
    final c = build(readFor: ['E1']);
    final w = pondOf(c, 'E1').checks.first as WaterCheck;
    expect(w.done, isTrue);
    expect(w.reading?.pondId, 'E1');
    expect((pondOf(c, 'E2').checks.first as WaterCheck).done, isFalse);
  });

  test('a pond read in this visit keeps its water check once empty', () {
    final c = build(ponds: [overview('E3', [])], readFor: ['E3']);
    expect(kinds(pondOf(c, 'E3')), [WaterCheck, InspectionCheck]);
    expect(pondOf(c, 'E3').checks.first.done, isTrue);
  });

  test('a batch sampled in this visit keeps its done sample check', () {
    final c = build(sampled: [('L1', 'E1')]);
    final s = pondOf(c, 'E1').checks.whereType<SampleCheck>().single;
    expect(s.done, isTrue);
    expect(s.sample?.batchId, 'L1');
    expect(pondOf(c, 'E2').checks.whereType<SampleCheck>(), isEmpty);
  });

  test('an inspection is done once all five are answered', () {
    final partial = build(observed: [for (final k in five.skip(1)) ('E1', k)]);
    expect(pondOf(partial, 'E1').checks.last.done, isFalse);
    final c = buildChecklist(
      ponds: [overview('E1', [])],
      readingsThisVisit: const [],
      samplesThisVisit: const [],
      batches: batches,
      observationsThisVisit: [
        observationRow('E1', ObservationCategory.dike, ok: false),
        for (final k in five.skip(1)) observationRow('E1', k),
      ],
      lastSampleOrStocking: const {},
      today: today,
      config: cfg,
    );
    final i = pondOf(c, 'E1').checks.single as InspectionCheck;
    expect(i.done, isTrue);
    expect(i.problems, [ObservationCategory.dike]);
  });

  test('free observations go to their pond or the farm', () {
    final c = buildChecklist(
      ponds: [overview('E1', [])],
      readingsThisVisit: const [],
      samplesThisVisit: const [],
      batches: batches,
      observationsThisVisit: [
        observationRow('E1', ObservationCategory.other, ok: null),
        observationRow(null, ObservationCategory.theft, ok: null),
        observationRow('E1', ObservationCategory.dike),
      ],
      lastSampleOrStocking: const {},
      today: today,
      config: cfg,
    );
    expect(pondOf(c, 'E1').observations.map((o) => o.category), [
      ObservationCategory.other,
    ]);
    expect(c.farmObservations.map((o) => o.category), [
      ObservationCategory.theft,
    ]);
  });

  test('done and total count checks; open lists what is left in order', () {
    final c = build(
      readFor: ['E1'],
      observed: [for (final k in five) ('E1', k)],
    );
    // E1: water, sample L1, inspection; E2: water, inspection.
    expect(c.total, 5);
    expect(c.done, 2);
    expect(
      [for (final (p, k) in c.open) '${p.code} ${k.runtimeType}'],
      ['E1 SampleCheck', 'E2 WaterCheck', 'E2 InspectionCheck'],
    );
  });

  test('ponds come in code order', () {
    final c = build(
      ponds: [
        overview('E2', ['L2']),
        overview('E1', ['L1']),
      ],
    );
    expect([for (final p in c.ponds) p.overview.pond.code], ['E1', 'E2']);
  });

  test('a sample of this visit stays once its batch has left the pond', () {
    // L1 was sampled in E1, then harvested or moved out: no fish of it left.
    final c = build(ponds: [overview('E1', [])], sampled: [('L1', 'E1')]);
    final s = pondOf(c, 'E1').checks.whereType<SampleCheck>().single;
    expect((s.batch.id, s.done), ('L1', true));
  });

  test('read twice in this visit, the latest reading and sample show', () {
    final early = readingRow('E1').copyWith(id: 'r1', ph: const Value(6.0));
    final late = readingRow('E1').copyWith(
      id: 'r2',
      ph: const Value(7.5),
      recordedAt: early.recordedAt.add(const Duration(hours: 1)),
    );
    final first = sampleRow('L1', 'E1').copyWith(id: 's1', fishCount: 30);
    final second = sampleRow('L1', 'E1').copyWith(
      id: 's2',
      fishCount: 40,
      recordedAt: first.recordedAt.add(const Duration(hours: 1)),
    );
    for (final (readings, samples) in [
      ([late, early], [second, first]),
      ([early, late], [first, second]),
    ]) {
      final c = buildChecklist(
        ponds: [
          overview('E1', ['L1']),
        ],
        readingsThisVisit: readings,
        samplesThisVisit: samples,
        observationsThisVisit: const [],
        batches: batches,
        lastSampleOrStocking: {('L1', 'E1'): DateTime(2026, 3, 1)},
        today: today,
        config: cfg,
      );
      final checks = pondOf(c, 'E1').checks;
      expect((checks.first as WaterCheck).reading?.id, 'r2');
      expect(checks.whereType<SampleCheck>().single.sample?.id, 's2');
    }
  });
}
