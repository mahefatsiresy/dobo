import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../common/farm_today.dart';
import '../ponds/pond_overview.dart';
import 'visit_checklist.dart';

final visitsProvider = StreamProvider<List<Visit>>(
  (ref) => ref.watch(visitRepositoryProvider).watchAll(),
);

final _readingsProvider = StreamProvider.family<List<WaterReading>, String>(
  (ref, visitId) =>
      ref.watch(readingRepositoryProvider).watchReadingsForVisit(visitId),
);

final _samplesProvider = StreamProvider.family<List<Sample>, String>(
  (ref, visitId) =>
      ref.watch(readingRepositoryProvider).watchSamplesForVisit(visitId),
);

final visitObservationsProvider =
    StreamProvider.family<List<Observation>, String>(
      (ref, visitId) =>
          ref.watch(observationRepositoryProvider).watchForVisit(visitId),
    );

final _lastSampleOrStockingProvider =
    StreamProvider<Map<(String, String), DateTime>>(
      (ref) => ref.watch(readingRepositoryProvider).watchLastSampleOrStocking(),
    );

/// What the open visit still has to do; null while loading.
final checklistProvider = Provider.family<VisitChecklist?, String>((
  ref,
  visitId,
) {
  final ponds = ref.watch(pondOverviewsProvider).value;
  final readings = ref.watch(_readingsProvider(visitId)).value;
  final samples = ref.watch(_samplesProvider(visitId)).value;
  final observations = ref.watch(visitObservationsProvider(visitId)).value;
  final last = ref.watch(_lastSampleOrStockingProvider).value;
  if (ponds == null ||
      readings == null ||
      samples == null ||
      observations == null ||
      last == null) {
    return null;
  }
  return buildChecklist(
    ponds: ponds,
    readingsThisVisit: readings,
    samplesThisVisit: samples,
    observationsThisVisit: observations,
    lastSampleOrStocking: last,
    today: ref.watch(farmTodayProvider),
    config: DomainConfig.defaults,
  );
});
