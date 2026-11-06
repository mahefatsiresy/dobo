import 'dart:convert';

import '../alerts/alert.dart';
import '../feed_stock.dart';
import '../growth.dart';
import '../stock.dart';
import '../types.dart';
import '../water.dart';

/// A published report's content was written by a newer app.
class UnsupportedReportFormat implements Exception {
  const UnsupportedReportFormat(this.format);

  final int format;
}

/// What a visit report shows (SPEC F8), frozen when it is published: every
/// phone draws the same numbers, in its own language. Ids are kept with
/// [pondCodes] and [batchCodes] so the report reads the same after a pond
/// is renamed or archived.
class ReportContent {
  const ReportContent({
    this.format = currentFormat,
    required this.header,
    this.summary,
    this.pondCodes = const {},
    this.batchCodes = const {},
    this.alerts = const [],
    this.health = const [],
    this.water = const [],
    this.growth = const [],
    this.feed = const [],
    this.feedTotalG = 0,
    this.feedStock,
    this.next = const [],
    this.observations = const [],
    this.visitPhotoKeys = const [],
  });

  /// 2 (M7): typed feed stock; Next items for prep steps.
  static const currentFormat = 2;

  final int format;
  final ReportHeader header;
  final String? summary;
  final Map<String, String> pondCodes;
  final Map<String, String> batchCodes;

  /// Open danger and warning alerts when it was published.
  final List<Alert> alerts;

  /// Ponds with deaths, signs, health events or treatments in the period.
  final List<PondHealth> health;

  /// Ponds holding fish, with their latest reading.
  final List<PondWater> water;

  /// One line per batch in a pond with live fish.
  final List<BatchGrowth> growth;

  /// Feed given in the period, per pond.
  final List<PondFeed> feed;
  final int feedTotalG;

  /// Stock on hand and lot ages; null before any delivery is on record,
  /// and in format-1 reports.
  final FeedStockSection? feedStock;
  final List<NextItem> next;
  final List<ReportObservation> observations;
  final List<String> visitPhotoKeys;

  /// Every photo the report shows.
  List<String> get photoKeys => [
    for (final h in health)
      for (final e in h.events) ...e.photoKeys,
    for (final o in observations) ...o.photoKeys,
    ...visitPhotoKeys,
  ];

  Map<String, Object?> toJson() => {
    'format': format,
    'header': header.toJson(),
    'summary': summary,
    'pondCodes': pondCodes,
    'batchCodes': batchCodes,
    'alerts': [for (final a in alerts) alertToJson(a)],
    'health': [for (final h in health) h.toJson()],
    'water': [for (final w in water) w.toJson()],
    'growth': [for (final g in growth) g.toJson()],
    'feed': [for (final f in feed) f.toJson()],
    'feedTotalG': feedTotalG,
    'feedStock': feedStock?.toJson(),
    'next': [for (final n in next) n.toJson()],
    'observations': [for (final o in observations) o.toJson()],
    'visitPhotoKeys': visitPhotoKeys,
  };

  /// Throws [UnsupportedReportFormat] for content from a newer app.
  /// Any value this app can't read (a newer enum value, a wrong type) also
  /// throws it: a report is permanent synced data and must never break the
  /// screens that list it.
  factory ReportContent.fromJson(Map<String, Object?> j) {
    final format = j['format'];
    if (format is! int || format > currentFormat) {
      throw UnsupportedReportFormat(format is int ? format : -1);
    }
    try {
      return ReportContent._fromJson(format, j);
    } on Object catch (e) {
      if (e is UnsupportedReportFormat) rethrow;
      throw UnsupportedReportFormat(format);
    }
  }

  factory ReportContent._fromJson(int format, Map<String, Object?> j) {
    return ReportContent(
      format: format,
      header: ReportHeader.fromJson(_map(j['header'])),
      summary: j['summary'] as String?,
      pondCodes: _strings(j['pondCodes']),
      batchCodes: _strings(j['batchCodes']),
      alerts: [for (final a in _list(j['alerts'])) alertFromJson(_map(a))],
      health: [
        for (final h in _list(j['health'])) PondHealth.fromJson(_map(h)),
      ],
      water: [for (final w in _list(j['water'])) PondWater.fromJson(_map(w))],
      growth: [
        for (final g in _list(j['growth'])) BatchGrowth.fromJson(_map(g)),
      ],
      feed: [for (final f in _list(j['feed'])) PondFeed.fromJson(_map(f))],
      feedTotalG: j['feedTotalG'] as int,
      feedStock: j['feedStock'] == null
          ? null
          : FeedStockSection.fromJson(_map(j['feedStock'])),
      next: [for (final n in _list(j['next'])) NextItem.fromJson(_map(n))],
      observations: [
        for (final o in _list(j['observations']))
          ReportObservation.fromJson(_map(o)),
      ],
      visitPhotoKeys: _keys(j['visitPhotoKeys']),
    );
  }

  /// This content as published: with the member's final [summary], at
  /// [builtAt].
  ReportContent publishedAs({
    required String? summary,
    required DateTime builtAt,
  }) => ReportContent(
    format: format,
    header: ReportHeader(
      siteName: header.siteName,
      visitDay: header.visitDay,
      memberName: header.memberName,
      groupName: header.groupName,
      periodFrom: header.periodFrom,
      periodTo: header.periodTo,
      builtAt: builtAt,
    ),
    summary: summary,
    pondCodes: pondCodes,
    batchCodes: batchCodes,
    alerts: alerts,
    health: health,
    water: water,
    growth: growth,
    feed: feed,
    feedTotalG: feedTotalG,
    feedStock: feedStock,
    next: next,
    observations: observations,
    visitPhotoKeys: visitPhotoKeys,
  );

  String encode() => jsonEncode(toJson());

  static ReportContent decode(String json) {
    final Object? parsed;
    try {
      parsed = jsonDecode(json);
    } on FormatException {
      throw const UnsupportedReportFormat(-1);
    }
    if (parsed is! Map) throw const UnsupportedReportFormat(-1);
    return ReportContent.fromJson(_map(parsed));
  }
}

class ReportHeader {
  const ReportHeader({
    required this.siteName,
    required this.visitDay,
    required this.memberName,
    this.groupName,
    required this.periodFrom,
    required this.periodTo,
    required this.builtAt,
  });

  final String siteName;

  /// Farm days, as `farmDateToUtc` stores them.
  final DateTime visitDay;
  final String memberName;
  final String? groupName;
  final DateTime periodFrom;
  final DateTime periodTo;

  /// When it was published.
  final DateTime builtAt;

  Map<String, Object?> toJson() => {
    'siteName': siteName,
    'visitDay': _date(visitDay),
    'memberName': memberName,
    'groupName': groupName,
    'periodFrom': _date(periodFrom),
    'periodTo': _date(periodTo),
    'builtAt': _date(builtAt),
  };

  factory ReportHeader.fromJson(Map<String, Object?> j) => ReportHeader(
    siteName: j['siteName'] as String,
    visitDay: _parse(j['visitDay'])!,
    memberName: j['memberName'] as String,
    groupName: j['groupName'] as String?,
    periodFrom: _parse(j['periodFrom'])!,
    periodTo: _parse(j['periodTo'])!,
    builtAt: _parse(j['builtAt'])!,
  );
}

/// Deaths one person saw. A null [name] is someone this phone didn't know.
class ObserverDeaths {
  const ObserverDeaths({required this.name, required this.deaths});

  final String? name;
  final int deaths;

  Map<String, Object?> toJson() => {'name': name, 'deaths': deaths};

  factory ObserverDeaths.fromJson(Map<String, Object?> j) =>
      ObserverDeaths(name: j['name'] as String?, deaths: j['deaths'] as int);
}

class PondHealth {
  const PondHealth({
    required this.pondId,
    this.deaths = 0,
    this.byObserver = const [],
    this.signs = const [],
    this.events = const [],
    this.treatments = const [],
  });

  final String pondId;
  final int deaths;

  /// Most deaths first.
  final List<ObserverDeaths> byObserver;

  /// Warning signs and signs on dead fish from daily logs, by day.
  final List<DatedSigns> signs;
  final List<HealthLine> events;
  final List<TreatmentLine> treatments;

  Map<String, Object?> toJson() => {
    'pondId': pondId,
    'deaths': deaths,
    'byObserver': [for (final o in byObserver) o.toJson()],
    'signs': [
      for (final s in signs) {'date': _date(s.date), 'signs': _names(s.signs)},
    ],
    'events': [for (final e in events) e.toJson()],
    'treatments': [for (final t in treatments) t.toJson()],
  };

  factory PondHealth.fromJson(Map<String, Object?> j) => PondHealth(
    pondId: j['pondId'] as String,
    deaths: j['deaths'] as int,
    byObserver: [
      for (final o in _list(j['byObserver'])) ObserverDeaths.fromJson(_map(o)),
    ],
    signs: [
      for (final s in _list(j['signs']))
        DatedSigns(
          _parse(_map(s)['date'])!,
          _enums(WarningSign.values, _map(s)['signs']),
        ),
    ],
    events: [for (final e in _list(j['events'])) HealthLine.fromJson(_map(e))],
    treatments: [
      for (final t in _list(j['treatments'])) TreatmentLine.fromJson(_map(t)),
    ],
  );
}

class HealthLine {
  const HealthLine({
    required this.at,
    this.signs = const {},
    this.suspectedIssue,
    this.actions = const {},
    this.photoKeys = const [],
  });

  final DateTime at;
  final Set<WarningSign> signs;
  final String? suspectedIssue;
  final Set<HealthAction> actions;
  final List<String> photoKeys;

  Map<String, Object?> toJson() => {
    'at': _date(at),
    'signs': _names(signs),
    'suspectedIssue': suspectedIssue,
    'actions': _names(actions),
    'photoKeys': photoKeys,
  };

  factory HealthLine.fromJson(Map<String, Object?> j) => HealthLine(
    at: _parse(j['at'])!,
    signs: _enums(WarningSign.values, j['signs']),
    suspectedIssue: j['suspectedIssue'] as String?,
    actions: _enums(HealthAction.values, j['actions']),
    photoKeys: _keys(j['photoKeys']),
  );
}

class TreatmentLine {
  const TreatmentLine({
    required this.at,
    this.batchId,
    required this.product,
    required this.dose,
    this.advisedBy,
  });

  final DateTime at;
  final String? batchId;
  final String product;
  final String dose;
  final String? advisedBy;

  Map<String, Object?> toJson() => {
    'at': _date(at),
    'batchId': batchId,
    'product': product,
    'dose': dose,
    'advisedBy': advisedBy,
  };

  factory TreatmentLine.fromJson(Map<String, Object?> j) => TreatmentLine(
    at: _parse(j['at'])!,
    batchId: j['batchId'] as String?,
    product: j['product'] as String,
    dose: j['dose'] as String,
    advisedBy: j['advisedBy'] as String?,
  );
}

/// A pond's latest reading; [at] is null when it has none.
class PondWater {
  const PondWater({
    required this.pondId,
    this.at,
    this.temperatureC,
    this.ph,
    this.oxygenMgL,
    this.colour,
    this.issues = const [],
  });

  final String pondId;
  final DateTime? at;
  final double? temperatureC;
  final double? ph;
  final double? oxygenMgL;
  final WaterColour? colour;
  final List<WaterIssue> issues;

  Map<String, Object?> toJson() => {
    'pondId': pondId,
    'at': _date(at),
    'temperatureC': temperatureC,
    'ph': ph,
    'oxygenMgL': oxygenMgL,
    'colour': colour?.name,
    'issues': [
      for (final i in issues)
        {
          'param': i.param.name,
          'severity': i.severity.name,
          'value': i.value,
          'direction': i.direction?.name,
        },
    ],
  };

  factory PondWater.fromJson(Map<String, Object?> j) => PondWater(
    pondId: j['pondId'] as String,
    at: _parse(j['at']),
    temperatureC: _double(j['temperatureC']),
    ph: _double(j['ph']),
    oxygenMgL: _double(j['oxygenMgL']),
    colour: _enum(WaterColour.values, j['colour']),
    issues: [
      for (final raw in _list(j['issues']))
        if (_map(raw) case final i)
          WaterIssue(
            _enum(WaterParam.values, i['param'])!,
            _enum(Severity.values, i['severity'])!,
            value: _double(i['value']),
            direction: _enum(Direction.values, i['direction']),
          ),
    ],
  );
}

/// Why a growth line has no FCR number.
enum FcrNote { stalled, shared, noSample }

class BatchGrowth {
  const BatchGrowth({
    required this.batchId,
    required this.pondId,
    required this.avgWeightG,
    required this.weighedOn,
    required this.liveCount,
    required this.biomassG,
    this.fcr,
    this.fcrNote,
    this.trend,
    this.survival,
  });

  final String batchId;
  final String pondId;

  /// From the latest weighing point (arrival or sample).
  final double avgWeightG;
  final DateTime weighedOn;

  /// Estimated.
  final int liveCount;

  /// Estimated.
  final int biomassG;

  /// The latest period's FCR; null with [fcrNote] saying why.
  final double? fcr;
  final FcrNote? fcrNote;
  final FcrTrend? trend;

  /// The whole batch's, over all its ponds.
  final double? survival;

  Map<String, Object?> toJson() => {
    'batchId': batchId,
    'pondId': pondId,
    'avgWeightG': avgWeightG,
    'weighedOn': _date(weighedOn),
    'liveCount': liveCount,
    'biomassG': biomassG,
    'fcr': fcr,
    'fcrNote': fcrNote?.name,
    'trend': trend?.name,
    'survival': survival,
  };

  factory BatchGrowth.fromJson(Map<String, Object?> j) => BatchGrowth(
    batchId: j['batchId'] as String,
    pondId: j['pondId'] as String,
    avgWeightG: _double(j['avgWeightG'])!,
    weighedOn: _parse(j['weighedOn'])!,
    liveCount: j['liveCount'] as int,
    biomassG: j['biomassG'] as int,
    fcr: _double(j['fcr']),
    fcrNote: _enum(FcrNote.values, j['fcrNote']),
    trend: _enum(FcrTrend.values, j['trend']),
    survival: _double(j['survival']),
  );
}

class PondFeed {
  const PondFeed({required this.pondId, required this.feedG});

  final String pondId;
  final int feedG;

  Map<String, Object?> toJson() => {'pondId': pondId, 'feedG': feedG};

  factory PondFeed.fromJson(Map<String, Object?> j) =>
      PondFeed(pondId: j['pondId'] as String, feedG: j['feedG'] as int);
}

/// Feed on hand when the report was published (format 2).
class FeedStockSection {
  const FeedStockSection({
    required this.onHandG,
    required this.daysLeft,
    required this.overdrawnG,
    this.lots = const [],
  });

  final int onHandG;
  final double? daysLeft;
  final int overdrawnG;

  /// Lots still holding feed, oldest first.
  final List<FeedLotLine> lots;

  Map<String, Object?> toJson() => {
    'onHandG': onHandG,
    'daysLeft': daysLeft,
    'overdrawnG': overdrawnG,
    'lots': [for (final l in lots) l.toJson()],
  };

  factory FeedStockSection.fromJson(Map<String, Object?> j) => FeedStockSection(
    onHandG: j['onHandG'] as int,
    daysLeft: _double(j['daysLeft']),
    overdrawnG: j['overdrawnG'] as int,
    lots: [for (final l in _list(j['lots'])) FeedLotLine.fromJson(_map(l))],
  );
}

class FeedLotLine {
  const FeedLotLine({
    this.label,
    required this.phase,
    required this.manufacturedOn,
    required this.balanceG,
    required this.age,
  });

  final String? label;
  final Phase phase;
  final DateTime manufacturedOn;
  final int balanceG;
  final FeedAge age;

  Map<String, Object?> toJson() => {
    'label': label,
    'phase': phase.name,
    'manufacturedOn': _date(manufacturedOn),
    'balanceG': balanceG,
    'age': age.name,
  };

  factory FeedLotLine.fromJson(Map<String, Object?> j) => FeedLotLine(
    label: j['label'] as String?,
    phase: _enum(Phase.values, j['phase'])!,
    manufacturedOn: _parse(j['manufacturedOn'])!,
    balanceG: j['balanceG'] as int,
    age: _enum(FeedAge.values, j['age'])!,
  );
}

enum NextKind { sample, harvest, quarantineRelease, prepStep }

class NextItem {
  const NextItem({
    required this.kind,
    required this.date,
    required this.pondId,
    this.batchId,
    this.step,
  });

  final NextKind kind;
  final DateTime date;
  final String pondId;

  /// Null for a prep step, which is about an empty pond.
  final String? batchId;

  /// The prep step awaited (`dry` or `rest`) for [NextKind.prepStep].
  final PrepStep? step;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'date': _date(date),
    'pondId': pondId,
    'batchId': batchId,
    if (step != null) 'step': step!.name,
  };

  factory NextItem.fromJson(Map<String, Object?> j) => NextItem(
    kind: _enum(NextKind.values, j['kind'])!,
    date: _parse(j['date'])!,
    pondId: j['pondId'] as String,
    batchId: j['batchId'] as String?,
    step: _enum(PrepStep.values, j['step']),
  );
}

/// A condition check (`ok` set) or a free observation.
class ReportObservation {
  const ReportObservation({
    this.pondId,
    required this.category,
    this.ok,
    this.note,
    this.photoKeys = const [],
  });

  final String? pondId;
  final ObservationCategory category;
  final bool? ok;
  final String? note;
  final List<String> photoKeys;

  Map<String, Object?> toJson() => {
    'pondId': pondId,
    'category': category.name,
    'ok': ok,
    'note': note,
    'photoKeys': photoKeys,
  };

  factory ReportObservation.fromJson(Map<String, Object?> j) =>
      ReportObservation(
        pondId: j['pondId'] as String?,
        category: _enum(ObservationCategory.values, j['category'])!,
        ok: j['ok'] as bool?,
        note: j['note'] as String?,
        photoKeys: _keys(j['photoKeys']),
      );
}

// Alerts -----------------------------------------------------------------

Map<String, Object?> alertToJson(Alert a) => {
  'kind': a.kind.name,
  'severity': a.severity.name,
  'pondId': a.pondId,
  'batchId': a.batchId,
  'facts': {
    for (final MapEntry(:key, :value) in a.facts.entries)
      key: _encodeFact(value),
  },
};

Alert alertFromJson(Map<String, Object?> j) => Alert(
  _enum(AlertKind.values, j['kind'])!,
  _enum(Severity.values, j['severity'])!,
  pondId: j['pondId'] as String?,
  batchId: j['batchId'] as String?,
  facts: {
    for (final MapEntry(:key, :value) in _map(j['facts']).entries)
      key: _decodeFact(value),
  },
);

/// Every enum type found in alert facts, by the tag it is stored under.
const Map<String, List<Enum>> _factEnums = {
  'WaterParam': WaterParam.values,
  'Direction': Direction.values,
  'DensityStatus': DensityStatus.values,
  'Phase': Phase.values,
  'PrepStep': PrepStep.values,
  'WarningSign': WarningSign.values,
  'FeedAge': FeedAge.values,
};

/// Plain JSON values stay as they are; dates, enums and sets of enums are
/// tagged so they come back as the same type.
Object? _encodeFact(Object? v) => switch (v) {
  DateTime() => {'d': v.toUtc().toIso8601String()},
  Enum() => {'e': _enumTag(v), 'v': v.name},
  Set<WarningSign>() => {'s': 'WarningSign', 'v': _names(v)},
  List() => [for (final e in v) _encodeFact(e)],
  _ => v,
};

String _enumTag(Enum e) {
  for (final MapEntry(:key, :value) in _factEnums.entries) {
    if (value.contains(e)) return key;
  }
  throw ArgumentError('Alert fact enum not registered: ${e.runtimeType}');
}

Object? _decodeFact(Object? v) {
  if (v is List) return [for (final e in v) _decodeFact(e)];
  if (v is! Map) return v;
  final m = _map(v);
  if (m.containsKey('d')) return DateTime.parse(m['d'] as String);
  if (m.containsKey('e')) {
    return _factEnums[m['e']]!.byName(m['v'] as String);
  }
  if (m.containsKey('s')) {
    // Typed, as the alert texts cast it (only signs come as sets).
    return _enums(WarningSign.values, m['v']);
  }
  return m;
}

// JSON helpers -----------------------------------------------------------

Map<String, Object?> _map(Object? v) => (v as Map).cast<String, Object?>();

List<Object?> _list(Object? v) => v == null ? const [] : (v as List);

Map<String, String> _strings(Object? v) =>
    v == null ? const {} : (v as Map).cast<String, String>();

List<String> _keys(Object? v) => [for (final k in _list(v)) k as String];

String? _date(DateTime? t) => t?.toUtc().toIso8601String();

DateTime? _parse(Object? v) => v == null ? null : DateTime.parse(v as String);

double? _double(Object? v) => (v as num?)?.toDouble();

List<String> _names(Iterable<Enum> values) => [for (final e in values) e.name];

T? _enum<T extends Enum>(List<T> values, Object? name) =>
    name == null ? null : values.byName(name as String);

Set<T> _enums<T extends Enum>(List<T> values, Object? names) => {
  for (final n in _list(names)) values.byName(n as String),
};
