import '../../db/database.dart';
import '../../domain/alerts/schedule_alerts.dart';
import '../../domain/config.dart';
import '../../domain/types.dart';
import '../ponds/pond_overview.dart';

/// The pond checks a visit walks through (SPEC F5).
const conditionCategories = [
  ObservationCategory.dike,
  ObservationCategory.inletScreen,
  ObservationCategory.predatorNets,
  ObservationCategory.fence,
  ObservationCategory.grass,
];

/// One check of a pond during a visit (docs/design.md §Step 5): done once
/// this visit holds its record, which then stays in place.
sealed class VisitCheck {
  const VisitCheck();

  bool get done;
}

final class WaterCheck extends VisitCheck {
  const WaterCheck(this.reading);

  /// This visit's reading of the pond.
  final WaterReading? reading;

  @override
  bool get done => reading != null;
}

final class SampleCheck extends VisitCheck {
  const SampleCheck(this.batch, this.sample);

  final Batch batch;

  /// This visit's sample of the batch in the pond.
  final Sample? sample;

  @override
  bool get done => sample != null;
}

final class InspectionCheck extends VisitCheck {
  const InspectionCheck(this.answers);

  /// This visit's answer per condition category.
  final Map<ObservationCategory, Observation> answers;

  /// Categories answered "problem", in [conditionCategories] order.
  List<ObservationCategory> get problems => [
    for (final c in conditionCategories)
      if (answers[c]?.ok == false) c,
  ];

  @override
  bool get done => conditionCategories.every(answers.containsKey);
}

/// A pond's part of the visit: its checks (water, samples by batch code,
/// inspection) and the free observations about it.
class PondVisit {
  const PondVisit({
    required this.overview,
    required this.checks,
    required this.observations,
  });

  final PondOverview overview;
  final List<VisitCheck> checks;

  /// Free observations (no OK/problem answer) about this pond, oldest first.
  final List<Observation> observations;
}

/// A visit pond by pond, in code order (docs/design.md §Step 5).
class VisitChecklist {
  const VisitChecklist({required this.ponds, required this.farmObservations});

  final List<PondVisit> ponds;

  /// Free observations about no pond in particular.
  final List<Observation> farmObservations;

  int get total => ponds.fold(0, (n, p) => n + p.checks.length);

  int get done =>
      ponds.fold(0, (n, p) => n + p.checks.where((c) => c.done).length);

  /// The checks still to do, in pond order, then check order.
  List<(Pond, VisitCheck)> get open => [
    for (final p in ponds)
      for (final c in p.checks)
        if (!c.done) (p.overview.pond, c),
  ];
}

/// The visit's checklist from [ponds] (active ones) and the records made
/// during it. With no records, what a visit started now would cover.
VisitChecklist buildChecklist({
  required List<PondOverview> ponds,
  required List<WaterReading> readingsThisVisit,
  required List<Sample> samplesThisVisit,
  required List<Observation> observationsThisVisit,
  required Map<(String, String), DateTime> lastSampleOrStocking,
  required DateTime today,
  required DomainConfig config,
}) {
  final readings = {for (final r in readingsThisVisit) r.pondId: r};
  final samples = {for (final s in samplesThisVisit) (s.batchId, s.pondId): s};
  final answers = <String, Map<ObservationCategory, Observation>>{};
  final notes = <String?, List<Observation>>{};
  for (final o in observationsThisVisit) {
    if (o.ok == null) {
      (notes[o.pondId] ??= []).add(o);
    } else if (o.pondId != null) {
      (answers[o.pondId!] ??= {})[o.category] = o;
    }
  }

  bool sampleDue(String batchId, String pondId) {
    final last = lastSampleOrStocking[(batchId, pondId)];
    return last != null &&
        sampleDueAlert(
              pondId: pondId,
              batchId: batchId,
              lastSampleOrStocking: last,
              today: today,
              config: config,
            ) !=
            null;
  }

  PondVisit visitOf(PondOverview o) {
    final id = o.pond.id;
    final batches = [...o.batches]
      ..sort((a, b) => a.batch.code.compareTo(b.batch.code));
    return PondVisit(
      overview: o,
      checks: [
        if (o.liveCount > 0 || readings.containsKey(id))
          WaterCheck(readings[id]),
        for (final b in batches)
          if (samples.containsKey((b.batch.id, id)) ||
              (b.placement.live.count > 0 && sampleDue(b.batch.id, id)))
            SampleCheck(b.batch, samples[(b.batch.id, id)]),
        InspectionCheck(answers[id] ?? const {}),
      ],
      observations: notes[id] ?? const [],
    );
  }

  final sorted = [...ponds]..sort((a, b) => a.pond.code.compareTo(b.pond.code));
  return VisitChecklist(
    ponds: [for (final o in sorted) visitOf(o)],
    farmObservations: notes[null] ?? const [],
  );
}
