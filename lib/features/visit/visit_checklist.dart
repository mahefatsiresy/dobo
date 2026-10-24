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

/// What a visit still has to do.
class VisitChecklist {
  const VisitChecklist({
    required this.waterDue,
    required this.samplesDue,
    required this.conditionsDue,
  });

  /// Ponds holding fish with no water reading in this visit.
  final List<Pond> waterDue;

  /// (batch, pond) due for a sample (DOMAIN §Sampling) and not sampled in
  /// this visit.
  final List<(Batch, Pond)> samplesDue;

  /// Ponds whose five condition checks aren't all done in this visit.
  final List<Pond> conditionsDue;
}

VisitChecklist buildChecklist({
  required List<PondOverview> ponds,
  required List<WaterReading> readingsThisVisit,
  required List<Sample> samplesThisVisit,
  required List<Observation> observationsThisVisit,
  required Map<(String, String), DateTime> lastSampleOrStocking,
  required DateTime today,
  required DomainConfig config,
}) {
  final read = {for (final r in readingsThisVisit) r.pondId};
  final sampled = {for (final s in samplesThisVisit) (s.batchId, s.pondId)};
  final checked = <String, Set<ObservationCategory>>{};
  for (final o in observationsThisVisit) {
    if (o.pondId != null && o.ok != null) {
      (checked[o.pondId!] ??= {}).add(o.category);
    }
  }
  return VisitChecklist(
    waterDue: [
      for (final o in ponds)
        if (o.liveCount > 0 && !read.contains(o.pond.id)) o.pond,
    ],
    samplesDue: [
      for (final o in ponds)
        for (final b in o.batches)
          if (b.placement.live.count > 0 &&
              !sampled.contains((b.batch.id, o.pond.id)) &&
              lastSampleOrStocking[(b.batch.id, o.pond.id)] != null &&
              sampleDueAlert(
                    pondId: o.pond.id,
                    batchId: b.batch.id,
                    lastSampleOrStocking:
                        lastSampleOrStocking[(b.batch.id, o.pond.id)]!,
                    today: today,
                    config: config,
                  ) !=
                  null)
            (b.batch, o.pond),
    ],
    conditionsDue: [
      for (final o in ponds)
        if (!(checked[o.pond.id] ?? const {}).containsAll(conditionCategories))
          o.pond,
    ],
  );
}
