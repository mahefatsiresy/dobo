import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/dates.dart';
import '../../domain/fcr.dart';
import '../../domain/trace.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/file_slug.dart';
import '../common/pdf_theme.dart';

/// A stocking ([fromPond] null) or a move between ponds.
class TraceMove {
  const TraceMove({
    required this.at,
    this.fromPond,
    required this.toPond,
    required this.count,
    this.avgWeightG,
  });

  final DateTime at;
  final String? fromPond;
  final String toPond;
  final int count;
  final double? avgWeightG;
}

class TraceTreatment {
  const TraceTreatment({
    required this.at,
    required this.pond,
    required this.product,
    required this.dose,
    this.advisedBy,
  });

  final DateTime at;
  final String pond;
  final String product;
  final String dose;
  final String? advisedBy;
}

class TraceSale {
  const TraceSale({
    required this.at,
    required this.customer,
    required this.form,
    required this.weightG,
  });

  final DateTime at;
  final String customer;
  final ProductForm form;
  final int weightG;
}

class TraceHarvest {
  const TraceHarvest({
    required this.at,
    required this.pond,
    required this.count,
    required this.weightG,
    required this.isFinal,
    this.sales = const [],
  });

  final DateTime at;
  final String pond;
  final int count;
  final int weightG;
  final bool isFinal;
  final List<TraceSale> sales;
}

/// Everything a batch's traceability sheet shows (Annex C), loaded.
class BatchTraceView {
  const BatchTraceView({
    required this.code,
    this.strain,
    this.hatchery,
    this.certificateNo,
    this.monosex,
    this.stockedOn,
    this.stockedAvgWeightG,
    required this.trace,
    this.moves = const [],
    this.treatments = const [],
    this.harvests = const [],
  });

  final String code;
  final String? strain;
  final String? hatchery;
  final String? certificateNo;
  final bool? monosex;
  final DateTime? stockedOn;
  final double? stockedAvgWeightG;
  final BatchTrace trace;
  final List<TraceMove> moves;
  final List<TraceTreatment> treatments;
  final List<TraceHarvest> harvests;
}

class TraceSection {
  const TraceSection(this.heading, this.lines);

  final String heading;
  final List<String> lines;
}

/// The sheet's sections, in [l10n]'s language (plan M7 Decision 15).
List<TraceSection> traceSections(
  BatchTraceView v,
  AppLocalizations l10n,
  Locale locale,
) {
  final t = v.trace;
  String estimated(String text) => '$text (${l10n.estimated})';
  List<String> orNothing(List<String> lines) =>
      lines.isEmpty ? [l10n.reportNothing] : lines;
  final fcr = switch (t.cycleFcr) {
    null => l10n.traceCycleOngoing,
    FcrValue(:final value) => estimated(
      formatDecimal(value, locale, decimals: 2),
    ),
    FcrStalled() => l10n.fcrStalled,
  };
  return [
    TraceSection(l10n.traceBatch(v.code), [
      if (v.strain != null) l10n.labelValue(l10n.strain, v.strain!),
      if (v.hatchery != null) l10n.labelValue(l10n.hatchery, v.hatchery!),
      if (v.certificateNo != null)
        l10n.labelValue(l10n.certificate, v.certificateNo!),
      if (v.monosex == true) l10n.monosex,
      if (v.stockedOn != null && v.stockedAvgWeightG != null)
        l10n.initialStock(
          formatCount(t.stockedCount, locale),
          formatGrams(v.stockedAvgWeightG!, locale),
          formatDate(v.stockedOn!),
        ),
    ]),
    TraceSection(
      l10n.tracePonds,
      orNothing([
        for (final m in v.moves)
          l10n.labelValue(
            formatDate(m.at),
            [
              m.fromPond == null
                  ? '${l10n.eventStocking} ${m.toPond}'
                  : '${l10n.eventTransfer} ${m.fromPond} → ${m.toPond}',
              formatCount(m.count, locale),
              if (m.avgWeightG != null) formatGrams(m.avgWeightG!, locale),
            ].join(l10n.reportListSeparator),
          ),
      ]),
    ),
    TraceSection(
      l10n.traceTreatments,
      orNothing([
        for (final tr in v.treatments)
          l10n.labelValue(
            formatDate(tr.at),
            [
              tr.pond,
              '${tr.product}, ${tr.dose}',
              if (tr.advisedBy != null) l10n.traceAdvisedBy(tr.advisedBy!),
            ].join(l10n.reportListSeparator),
          ),
      ]),
    ),
    TraceSection(
      l10n.traceHarvests,
      orNothing([
        for (final h in v.harvests)
          l10n.harvestLine(
            formatDate(h.at),
            h.isFinal ? l10n.harvestKindFinal : l10n.harvestKindPartial,
            h.pond,
            formatCount(h.count, locale),
            formatKg(h.weightG, locale),
          ),
      ]),
    ),
    TraceSection(
      l10n.traceSales,
      orNothing([
        for (final h in v.harvests)
          for (final s in h.sales)
            l10n.labelValue(
              formatDate(s.at),
              l10n.saleLine(
                s.customer,
                l10n.productForm(s.form),
                formatKg(s.weightG, locale),
              ),
            ),
      ]),
    ),
    TraceSection(l10n.traceResults, [
      l10n.labelValue(
        l10n.traceStocked,
        '${formatCount(t.stockedCount, locale)} · '
        '${formatKg(t.stockedWeightG, locale)}',
      ),
      l10n.labelValue(
        l10n.traceHarvested,
        '${formatCount(t.harvestedCount, locale)} · '
        '${formatKg(t.harvestedWeightG, locale)}',
      ),
      if (t.live > 0)
        l10n.labelValue(l10n.traceLive, estimated(formatCount(t.live, locale))),
      l10n.labelValue(
        l10n.traceFeed,
        estimated(formatKg(t.batchFeedG, locale)),
      ),
      l10n.labelValue(l10n.traceCycleFcr, fcr),
      if (t.survival != null)
        l10n.labelValue(
          l10n.traceSurvival,
          '${formatDecimal(t.survival! * 100, locale, decimals: 0)} %',
        ),
      if (t.unaccounted > 0)
        l10n.labelValue(
          l10n.traceUnaccounted,
          formatCount(t.unaccounted, locale),
        ),
    ]),
  ];
}

/// The sheet as an A4 PDF (SPEC F12, Annex C).
Future<Uint8List> buildTracePdf(
  BatchTraceView view,
  AppLocalizations l10n,
  Locale locale, {
  required pw.Font regular,
  required pw.Font bold,
  pw.Font? symbols,
}) {
  final doc = pw.Document(
    theme: pdfTheme(regular: regular, bold: bold, symbols: symbols),
    title: l10n.traceTitle,
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(color: PdfColors.grey700),
        ),
      ),
      build: (context) => [
        pw.Text(l10n.traceTitle, style: pw.TextStyle(font: bold, fontSize: 18)),
        for (final s in traceSections(view, l10n, locale)) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
            child: pw.Text(
              s.heading,
              style: pw.TextStyle(font: bold, fontSize: 13),
            ),
          ),
          for (final line in s.lines)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
              child: pw.Text(line),
            ),
        ],
      ],
    ),
  );
  return doc.save();
}

/// `tracabilite-<batch code>-<yyyy-mm-dd>.pdf`, safe on any file system.
String traceFileName(String code, DateTime day) {
  final d = farmDate(day);
  String two(int n) => n.toString().padLeft(2, '0');
  return 'tracabilite-${fileSlug(code, 'lot')}-'
      '${d.year}-${two(d.month)}-${two(d.day)}.pdf';
}
