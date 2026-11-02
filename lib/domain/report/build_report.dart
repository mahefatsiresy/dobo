import '../alerts/alert.dart';
import '../alerts/farm_alerts.dart';
import '../config.dart';
import '../dates.dart';
import '../farm_facts.dart';
import '../fcr.dart';
import '../growth.dart';
import '../occupancy.dart';
import '../people.dart';
import '../types.dart';
import '../water.dart';
import 'report_content.dart';

/// Days a first report covers, up to and including the visit day. A display
/// choice, not a farming number.
const firstReportDays = 7;

/// Farm days a report covers, both included: from the previous report's
/// last day (so a log written that evening still lands in a report), or
/// [firstReportDays] back.
(DateTime from, DateTime to) reportPeriod({
  required DateTime visitDay,
  DateTime? previousPeriodTo,
}) {
  final day = farmDate(visitDay);
  final from =
      previousPeriodTo ??
      farmDateToUtc(DateTime(day.year, day.month, day.day - firstReportDays));
  return (from, farmDateToUtc(day));
}

/// Everything a report is built from, already loaded.
class ReportInputs {
  const ReportInputs({
    required this.header,
    this.summary,
    required this.facts,
    required this.pondCodes,
    required this.batchCodes,
    required this.batches,
    this.alerts = const [],
    this.latestReadings = const {},
    this.healthLines = const [],
    this.treatments = const [],
    this.observations = const [],
    this.visitPhotoKeys = const [],
    required this.people,
    required this.config,
  });

  final ReportHeader header;
  final String? summary;
  final FarmFacts facts;

  /// The active ponds; only these appear.
  final Map<String, String> pondCodes;
  final Map<String, String> batchCodes;
  final Map<String, BatchInfo> batches;

  /// Open alerts, sorted as on the Alerts tab.
  final List<Alert> alerts;
  final Map<String, ReadingInfo> latestReadings;

  /// Health events and treatments dated in the period, with their pond.
  final List<(String pondId, HealthLine line)> healthLines;
  final List<(String pondId, TreatmentLine line)> treatments;
  final List<ReportObservation> observations;
  final List<String> visitPhotoKeys;
  final PeopleDirectory people;
  final DomainConfig config;
}

/// The report's content from [inputs] (SPEC F8; plan Decision 5).
ReportContent buildReportContent(ReportInputs inputs) {
  final f = inputs.facts;
  final from = inputs.header.periodFrom;
  final to = inputs.header.periodTo;
  bool inPeriod(DateTime t) =>
      daysBetween(from, t) >= 0 && daysBetween(t, to) >= 0;
  String code(String pondId) => inputs.pondCodes[pondId] ?? '';
  bool known(String pondId) => inputs.pondCodes.containsKey(pondId);

  final counted = [
    for (final l in countedLogs(f))
      if (known(l.pondId) && inPeriod(l.date)) l,
  ];
  final live =
      [
        for (final p in placementsOf(f))
          if (p.live.count > 0 && known(p.pondId)) p,
      ]..sort(
        (a, b) => _compare([
          (code(a.pondId), code(b.pondId)),
          (
            inputs.batchCodes[a.batchId] ?? '',
            inputs.batchCodes[b.batchId] ?? '',
          ),
        ]),
      );

  return ReportContent(
    header: inputs.header,
    summary: inputs.summary,
    pondCodes: inputs.pondCodes,
    batchCodes: inputs.batchCodes,
    alerts: inputs.alerts,
    health: _health(inputs, counted, inPeriod, known, code),
    water: _water(inputs, live),
    growth: [
      for (final p in live) _growth(f, p.batchId, p.pondId, p.live.count),
    ],
    feed: _feed(counted, code),
    feedTotalG: counted.fold(0, (sum, l) => sum + l.feedG),
    next: _next(inputs, live, code),
    observations: inputs.observations,
    visitPhotoKeys: inputs.visitPhotoKeys,
  );
}

List<PondHealth> _health(
  ReportInputs inputs,
  List<LogFact> counted,
  bool Function(DateTime) inPeriod,
  bool Function(String) known,
  String Function(String) code,
) {
  final deaths = <String, Map<String, (String?, int)>>{};
  for (final l in counted.where((l) => l.deaths > 0)) {
    final key = inputs.people.observerKey(
      observedBy: l.observedBy,
      enteredBy: l.enteredBy,
    );
    final name = inputs.people.observerName(
      observedBy: l.observedBy,
      enteredBy: l.enteredBy,
    );
    final byPond = deaths.putIfAbsent(l.pondId, () => {});
    byPond[key] = (name, (byPond[key]?.$2 ?? 0) + l.deaths);
  }
  // Signs read every log, as alerts do: a duplicate's signs still count.
  final signs = <String, Map<int, (DateTime, Set<WarningSign>)>>{};
  for (final l in inputs.facts.logs) {
    if (l.signs.isEmpty || !known(l.pondId) || !inPeriod(l.date)) continue;
    final day = farmDayNumber(l.date);
    final byDay = signs.putIfAbsent(l.pondId, () => {});
    final entry = byDay.putIfAbsent(day, () => (l.date, <WarningSign>{}));
    entry.$2.addAll(l.signs);
  }
  final ponds = {
    ...deaths.keys,
    ...signs.keys,
    for (final (p, _) in inputs.healthLines)
      if (known(p)) p,
    for (final (p, _) in inputs.treatments)
      if (known(p)) p,
  }.toList()..sort((a, b) => code(a).compareTo(code(b)));
  return [
    for (final pondId in ponds)
      PondHealth(
        pondId: pondId,
        deaths: [for (final (_, n) in (deaths[pondId] ?? const {}).values) n]
            .fold(0, (a, b) => a + b),
        byObserver:
            [
              for (final (name, n) in (deaths[pondId] ?? const {}).values)
                ObserverDeaths(name: name, deaths: n),
            ]..sort(
              (a, b) => b.deaths != a.deaths
                  ? b.deaths.compareTo(a.deaths)
                  : (a.name ?? '').compareTo(b.name ?? ''),
            ),
        signs: [
          for (final (date, s) in (signs[pondId] ?? const {}).values)
            DatedSigns(farmDateToUtc(farmDate(date)), s),
        ]..sort((a, b) => a.date.compareTo(b.date)),
        events: [
          for (final (p, line) in inputs.healthLines)
            if (p == pondId) line,
        ],
        treatments: [
          for (final (p, line) in inputs.treatments)
            if (p == pondId) line,
        ],
      ),
  ];
}

List<PondWater> _water(ReportInputs inputs, List<Placement> live) {
  final ponds = {for (final p in live) p.pondId};
  return [
    for (final pondId in ponds)
      if (inputs.latestReadings[pondId] case final r?)
        PondWater(
          pondId: pondId,
          at: r.at,
          temperatureC: r.temperatureC,
          ph: r.ph,
          oxygenMgL: r.oxygenMgL,
          colour: r.colour,
          issues: waterIssues(
            temperatureC: r.temperatureC,
            ph: r.ph,
            oxygenMgL: r.oxygenMgL,
            colour: r.colour,
            config: inputs.config,
          ),
        )
      else
        PondWater(pondId: pondId),
  ];
}

BatchGrowth _growth(FarmFacts f, String batchId, String pondId, int live) {
  final points = weighPoints(f, batchId: batchId, pondId: pondId);
  final periods = fcrPeriods(f, batchId: batchId, pondId: pondId);
  final last = points.last;
  final latest = periods.lastOrNull;
  final (double? fcr, FcrNote? note) = switch (latest?.fcr) {
    _ when latest == null => (null, FcrNote.noSample),
    null => (null, FcrNote.shared),
    FcrStalled() => (null, FcrNote.stalled),
    FcrValue(:final value) => (value, null),
  };
  return BatchGrowth(
    batchId: batchId,
    pondId: pondId,
    avgWeightG: last.avgWeightG,
    weighedOn: last.date,
    liveCount: live,
    biomassG: (live * last.avgWeightG).round(),
    fcr: fcr,
    fcrNote: note,
    trend: fcrTrend(periods),
    survival: batchSurvival(f, batchId),
  );
}

List<PondFeed> _feed(List<LogFact> counted, String Function(String) code) {
  final byPond = <String, int>{};
  for (final l in counted) {
    byPond[l.pondId] = (byPond[l.pondId] ?? 0) + l.feedG;
  }
  return [
    for (final MapEntry(:key, :value) in byPond.entries)
      if (value > 0) PondFeed(pondId: key, feedG: value),
  ]..sort((a, b) => code(a.pondId).compareTo(code(b.pondId)));
}

List<NextItem> _next(
  ReportInputs inputs,
  List<Placement> live,
  String Function(String) code,
) {
  final f = inputs.facts;
  final cfg = inputs.config;
  DateTime plus(DateTime t, int days) {
    final day = farmDate(t);
    return farmDateToUtc(DateTime(day.year, day.month, day.day + days));
  }

  final items = <NextItem>[];
  for (final p in live) {
    final batchId = p.batchId;
    final pondId = p.pondId;
    final points = weighPoints(f, batchId: batchId, pondId: pondId);
    items.add(
      NextItem(
        kind: NextKind.sample,
        date: plus(points.last.date, cfg.sampleIntervalDays),
        pondId: pondId,
        batchId: batchId,
      ),
    );
    final batch = inputs.batches[batchId];
    if (batch == null) continue;
    if (batch.status == BatchStatus.quarantine) {
      final start = [
        for (final s in f.stockings)
          if (s.batchId == batchId) s.date,
      ].fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
      if (start != null) {
        items.add(
          NextItem(
            kind: NextKind.quarantineRelease,
            date: plus(start, cfg.quarantineDays.min),
            pondId: pondId,
            batchId: batchId,
          ),
        );
      }
    }
    final harvest = batch.plannedHarvestOn;
    if (harvest != null && daysBetween(inputs.header.visitDay, harvest) >= 0) {
      items.add(
        NextItem(
          kind: NextKind.harvest,
          date: farmDateToUtc(farmDate(harvest)),
          pondId: pondId,
          batchId: batchId,
        ),
      );
    }
  }
  return items..sort(
    (a, b) => a.date
        .compareTo(b.date)
        .orElse(() => _compare([(code(a.pondId), code(b.pondId))]))
        .orElse(() => a.kind.index.compareTo(b.kind.index)),
  );
}

/// The first non-equal comparison of [pairs].
int _compare(List<(String, String)> pairs) {
  for (final (a, b) in pairs) {
    final c = a.compareTo(b);
    if (c != 0) return c;
  }
  return 0;
}

extension on int {
  int orElse(int Function() next) => this != 0 ? this : next();
}
