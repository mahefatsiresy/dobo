import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feed/feed_providers.dart';
import '../prep/prep_providers.dart';
import '../../db/database.dart';
import '../../db/database_provider.dart';
import '../../db/repositories/providers.dart';
import '../../domain/alerts/farm_alerts.dart';
import '../../domain/dates.dart';
import '../../domain/report/build_report.dart';
import '../../domain/report/report_content.dart';
import '../../domain/types.dart';
import '../admin/members_screen.dart' show groupsProvider, membersProvider;
import '../alerts/alert_providers.dart';
import '../common/farm_today.dart';
import '../people/people_providers.dart';
import '../ponds/pond_overview.dart';
import '../visit/visit_providers.dart';

/// The site's published reports, newest first (SPEC F8).
final reportsProvider = StreamProvider<List<VisitReport>>(
  (ref) => ref.watch(reportRepositoryProvider).watchAll(),
);

/// A published report's content: loading until its row is here, then null
/// when a newer app wrote it.
final reportContentProvider =
    Provider.family<AsyncValue<ReportContent?>, String>((ref, reportId) {
      final row = ref
          .watch(reportsProvider)
          .value
          ?.where((r) => r.id == reportId)
          .firstOrNull;
      if (row == null) return const AsyncLoading();
      try {
        return AsyncData(ReportContent.decode(row.content));
      } on UnsupportedReportFormat {
        return const AsyncData(null);
      }
    });

final unreadReportIdsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(reportRepositoryProvider).watchUnreadIds(),
);

/// Reports someone else published that this phone hasn't opened.
final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(unreadReportIdsProvider).value?.length ?? 0,
);

final _latestEndedProvider = StreamProvider<Visit?>(
  (ref) => ref.watch(visitRepositoryProvider).watchLatestEndedByMe(),
);

/// My latest ended visit while it has no report (plan Decision 4).
final draftVisitProvider = Provider<Visit?>((ref) {
  final visit = ref.watch(_latestEndedProvider).value;
  final reports = ref.watch(reportsProvider).value;
  if (visit == null || reports == null) return null;
  return reports.any((r) => r.visitId == visit.id) ? null : visit;
});

/// The farm day a visit belongs to: the day it ended.
DateTime visitDayOf(Visit v) =>
    farmDateToUtc(farmDate(v.endedAt ?? v.startedAt));

final _previousPeriodToProvider =
    StreamProvider.family<DateTime?, (DateTime, String)>(
      (ref, key) => ref
          .watch(reportRepositoryProvider)
          .watchPreviousPeriodTo(visitDay: key.$1, excludingVisitId: key.$2),
    );

final _healthBetweenProvider =
    StreamProvider.family<List<HealthEvent>, (DateTime, DateTime)>(
      (ref, p) =>
          ref.watch(healthRepositoryProvider).watchEventsBetween(p.$1, p.$2),
    );

final _treatmentsBetweenProvider =
    StreamProvider.family<List<Treatment>, (DateTime, DateTime)>(
      (ref, p) => ref
          .watch(healthRepositoryProvider)
          .watchTreatmentsBetween(p.$1, p.$2),
    );

final _photosProvider = StreamProvider<List<Photo>>(
  (ref) => ref.watch(photoRepositoryProvider).watchAll(),
);

/// The site's name.
final siteNameProvider = StreamProvider<String>((ref) {
  final db = ref.watch(databaseProvider);
  final siteId = ref.watch(sessionProvider).requireValue!.siteId;
  return (db.select(
    db.sites,
  )..where((s) => s.id.equals(siteId))).watchSingle().map((s) => s.name);
});

/// The report [visitId] would publish now, rebuilt as its data changes
/// (plan Decision 4: drafts are never stored).
final draftReportProvider = Provider.family<AsyncValue<ReportContent>, String>((
  ref,
  visitId,
) {
  final visit = ref
      .watch(visitsProvider)
      .value
      ?.where((v) => v.id == visitId)
      .firstOrNull;
  if (visit == null) return const AsyncLoading();
  final visitDay = visitDayOf(visit);
  final previous = ref.watch(_previousPeriodToProvider((visitDay, visitId)));
  if (!previous.hasValue) return const AsyncLoading();
  final (from, to) = reportPeriod(
    visitDay: visitDay,
    previousPeriodTo: previous.value,
  );
  final facts = ref.watch(farmFactsProvider);
  final ponds = ref.watch(pondsProvider);
  final summaries = ref.watch(batchSummariesProvider);
  final alerts = ref.watch(alertsProvider);
  final readings = ref.watch(latestReadingsProvider);
  final health = ref.watch(_healthBetweenProvider((from, to)));
  final treatments = ref.watch(_treatmentsBetweenProvider((from, to)));
  final observations = ref.watch(visitObservationsProvider(visitId));
  final people = ref.watch(peopleDirectoryProvider);
  final members = ref.watch(membersProvider);
  final groups = ref.watch(groupsProvider);
  final site = ref.watch(siteNameProvider);
  final photos = ref.watch(_photosProvider);
  final feedStock = ref.watch(feedStockProvider);
  final prep = ref.watch(prepProgressAllProvider);
  if (!photos.hasValue ||
      !feedStock.hasValue ||
      !prep.hasValue ||
      !facts.hasValue ||
      !ponds.hasValue ||
      !summaries.hasValue ||
      !alerts.hasValue ||
      !readings.hasValue ||
      !health.hasValue ||
      !treatments.hasValue ||
      !observations.hasValue ||
      !people.hasValue ||
      !members.hasValue ||
      !groups.hasValue ||
      !site.hasValue) {
    return const AsyncLoading();
  }

  // Owners with photos are never corrected in v1 (free observations,
  // health events, visits), so their current id is the one photos carry.
  List<String> keysOf(PhotoOwner kind, String id) => [
    for (final p in photos.requireValue)
      if (p.ownerKind == kind && p.ownerId == id) p.photoKey,
  ];
  final author = members.requireValue
      .where((m) => m.id == visit.enteredBy)
      .firstOrNull;
  final group = groups.requireValue
      .where((g) => g.id == author?.groupId)
      .firstOrNull;
  return AsyncData(
    buildReportContent(
      ReportInputs(
        header: ReportHeader(
          siteName: site.requireValue,
          visitDay: visitDay,
          memberName: author?.name ?? '',
          groupName: group?.name,
          periodFrom: from,
          periodTo: to,
          builtAt: ref.watch(clockProvider)().toUtc(),
        ),
        summary: visit.summary,
        facts: facts.requireValue,
        pondCodes: {for (final p in ponds.requireValue) p.id: p.code},
        batchCodes: {
          for (final s in summaries.requireValue) s.batch.id: s.batch.code,
        },
        batches: {
          for (final s in summaries.requireValue)
            s.batch.id: BatchInfo(
              id: s.batch.id,
              status: s.batch.status,
              plannedHarvestOn: s.batch.plannedHarvestOn,
            ),
        },
        alerts: alerts.requireValue,
        feedStock: feedStock.requireValue,
        prep: prep.requireValue,
        latestReadings: {
          for (final MapEntry(key: pondId, value: r)
              in readings.requireValue.entries)
            pondId: ReadingInfo(
              at: r.recordedAt,
              temperatureC: r.temperatureC,
              ph: r.ph,
              oxygenMgL: r.oxygenMgL,
              colour: r.colour,
            ),
        },
        healthLines: [
          for (final e in health.requireValue)
            (
              e.pondId,
              HealthLine(
                at: e.recordedAt,
                signs: e.signs,
                suspectedIssue: e.suspectedIssue,
                actions: e.actions,
                photoKeys: keysOf(PhotoOwner.healthEvent, e.id),
              ),
            ),
        ],
        treatments: [
          for (final t in treatments.requireValue)
            (
              t.pondId,
              TreatmentLine(
                at: t.recordedAt,
                batchId: t.batchId,
                product: t.product,
                dose: t.dose,
                advisedBy: t.advisedBy,
              ),
            ),
        ],
        observations: [
          for (final o in observations.requireValue)
            ReportObservation(
              pondId: o.pondId,
              category: o.category,
              ok: o.ok,
              note: o.note,
              photoKeys: keysOf(PhotoOwner.observation, o.id),
            ),
        ],
        visitPhotoKeys: keysOf(PhotoOwner.visit, visitId),
        people: people.requireValue,
        config: ref.watch(domainConfigProvider),
      ),
    ),
  );
});
