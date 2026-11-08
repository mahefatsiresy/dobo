import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';

import '../../domain/config.dart';
import '../../domain/exports/register.dart';
import '../../domain/exports/weekly.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';

/// Where a batch's fingerlings came from (Annex A "Provenance alevins").
class BatchOrigin {
  const BatchOrigin({this.hatchery, this.certificateNo});

  final String? hatchery;
  final String? certificateNo;
}

/// The names an export prints instead of ids.
class ExportNames {
  const ExportNames({
    required this.site,
    this.ponds = const {},
    this.batches = const {},
    this.origins = const {},
    this.customers = const {},
  });

  final String site;

  /// Every pond, archived ones included.
  final Map<String, String> ponds;
  final Map<String, String> batches;
  final Map<String, BatchOrigin> origins;
  final Map<String, String> customers;

  String pond(String id) => ponds[id] ?? '?';
  String batch(String id) => batches[id] ?? '?';
}

/// A table ready for PDF or CSV, in one language.
class ExportTable {
  const ExportTable({
    required this.title,
    required this.period,
    required this.header,
    required this.rows,
    required this.nothing,
    this.footer,
  });

  final String title;

  /// Site and dates, under the title.
  final String period;
  final List<String> header;
  final List<List<String>> rows;

  /// What the PDF says when there are no rows.
  final String nothing;
  final String? footer;
}

/// A spreadsheet number: decimal comma, no grouping (plan M8 Decision 9).
String _n(double v) => formatForInput(v);
String _kg(int grams) => _n(grams / 1000);
String _weight(double g) => NumberFormat('0.#', 'fr').format(g);

String _range(Range<num> r, Locale locale) =>
    '${formatNumber(r.min.toDouble(), locale)}–'
    '${formatNumber(r.max.toDouble(), locale)}';

String _period(
  ExportNames names,
  AppLocalizations l10n,
  DateTime from,
  DateTime to,
) => '${names.site} · ${l10n.exportPeriod(formatDate(from), formatDate(to))}';

/// The production register (Annex A) for [rows] (plan M8 Decision 7).
ExportTable registerTable(
  List<RegisterRow> rows,
  ExportNames names,
  AppLocalizations l10n,
  Locale locale, {
  required DateTime from,
  required DateTime to,
}) {
  final sep = l10n.reportListSeparator;
  String pondBatch(String pond, List<String> batches) => [
    pond,
    if (batches.isNotEmpty) batches.map(names.batch).join(', '),
  ].join(' / ');
  String fish(int count, double? avgWeightG) => [
    formatCount(count, locale),
    if (avgWeightG != null) formatGrams(avgWeightG, locale),
  ].join(' × ');

  List<String> line(RegisterRow r) {
    var origin = '', feed = '', deaths = '', sold = '';
    late final String observations;
    var pond = names.pond(r.pondId);
    switch (r) {
      case LogRow(:final log):
        feed = _kg(log.feedG);
        if (log.deaths > 0) deaths = '${log.deaths}';
        observations = [
          if (log.signs.isNotEmpty)
            [for (final s in log.signs) l10n.warningSign(s)].join(', '),
          if (log.waterColour != null)
            l10n.labelValue(
              l10n.waterColourLabel,
              l10n.waterColour(log.waterColour!),
            ),
          if (log.note case final note? when note.trim().isNotEmpty)
            note.trim(),
        ].join(sep);
      case StockingRow(:final stocking):
        final o = names.origins[stocking.batchId];
        origin = [
          if (o?.hatchery case final h? when h.isNotEmpty) h,
          if (o?.certificateNo case final c? when c.isNotEmpty)
            l10n.labelValue(l10n.certificate, c),
        ].join(sep);
        observations = l10n.labelValue(
          l10n.eventStocking,
          fish(stocking.count, stocking.avgWeightG),
        );
      case TransferRow(:final transfer):
        pond = '$pond → ${names.pond(transfer.toPondId)}';
        observations = l10n.labelValue(
          l10n.eventTransfer,
          fish(transfer.count, transfer.avgWeightG),
        );
      case HarvestRow(:final harvest):
        observations = l10n.labelValue(
          harvest.isFinal ? l10n.harvestKindFinal : l10n.harvestKindPartial,
          '${l10n.exportFishCount(formatCount(harvest.count, locale))}'
          '$sep${formatKg(harvest.weightG, locale)}',
        );
      case SaleRow(:final sale):
        sold = _kg(sale.weightG);
        observations = [
          names.customers[sale.customerId] ?? '?',
          l10n.productForm(sale.form),
        ].join(sep);
      case TreatmentRow(:final treatment):
        observations = [
          l10n.labelValue(
            l10n.exportTreatment,
            '${treatment.product}, ${treatment.dose}',
          ),
          if (treatment.advisedBy case final who? when who.isNotEmpty)
            l10n.traceAdvisedBy(who),
        ].join(sep);
      case HealthRow(:final event):
        final details = [
          if (event.suspectedIssue case final i? when i.trim().isNotEmpty)
            i.trim(),
          if (event.signs.isNotEmpty)
            [for (final s in event.signs) l10n.warningSign(s)].join(', '),
          if (event.actions.isNotEmpty)
            [for (final a in event.actions) l10n.healthAction(a)].join(', '),
        ];
        observations = details.isEmpty
            ? l10n.exportHealth
            : l10n.labelValue(l10n.exportHealth, details.join(sep));
    }
    return [
      formatDate(r.date),
      pondBatch(pond, r.batchIds),
      origin,
      feed,
      deaths,
      sold,
      observations,
    ];
  }

  return ExportTable(
    title: l10n.exportRegisterTitle,
    period: _period(names, l10n, from, to),
    header: [
      l10n.exportColDate,
      l10n.exportColPondBatch,
      l10n.exportColOrigin,
      l10n.exportColFeedKg,
      l10n.exportColDeaths,
      l10n.exportColSalesKg,
      l10n.exportColObservations,
    ],
    rows: [for (final r in rows) line(r)],
    nothing: l10n.reportNothing,
  );
}

/// The weekly sheet (Annex B) for [rows], whose weeks run [from]–[to]
/// (plan M8 Decision 8). Thresholds in the footer come from [config].
ExportTable weeklyTable(
  List<WeeklyRow> rows,
  ExportNames names,
  DomainConfig config,
  AppLocalizations l10n,
  Locale locale, {
  required DateTime from,
  required DateTime to,
}) {
  String? opt(double? v) => v == null ? null : _n(v);
  String weights(Map<String, double> byBatch) => switch (byBatch.length) {
    0 => '',
    1 => _weight(byBatch.values.single),
    _ => [
      for (final e
          in byBatch.entries.toList()
            ..sort((a, b) => names.batch(a.key).compareTo(names.batch(b.key))))
        '${names.batch(e.key)} : ${_weight(e.value)} g',
    ].join(' ; '),
  };
  return ExportTable(
    title: l10n.exportWeeklyTitle,
    period: _period(names, l10n, from, to),
    header: [
      l10n.exportColPond,
      l10n.exportColWeekOf,
      l10n.exportColTemp,
      l10n.exportColPh,
      l10n.exportColOxygen,
      l10n.exportColFeedGivenKg,
      l10n.exportColDeaths,
      l10n.exportColAvgWeight,
    ],
    rows: [
      for (final r in rows)
        [
          names.pond(r.pondId),
          formatDate(r.weekStart),
          opt(r.temperatureC) ?? '',
          opt(r.ph) ?? '',
          opt(r.oxygenMgL) ?? '',
          r.loggedDays == 0 ? '' : _kg(r.feedG),
          r.loggedDays == 0 ? '' : '${r.deaths}',
          weights(r.avgWeightGByBatch),
        ],
    ],
    nothing: l10n.reportNothing,
    footer: l10n.exportThresholds(
      _range(config.temperatureC, locale),
      _range(config.ph, locale),
      formatNumber(config.minOxygenMgL, locale),
      _range(config.waterRenewalPctPerWeek, locale),
    ),
  );
}

/// [t] as CSV rows: its header and rows, no title (opens as a plain table).
List<List<String>> csvRows(ExportTable t) => [t.header, ...t.rows];
