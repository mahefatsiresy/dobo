import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Color, Locale;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/growth.dart';
import '../../domain/report/report_content.dart';
import '../../domain/report/report_order.dart';
import '../../domain/types.dart';
import '../../domain/water.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../common/pdf_theme.dart';
import '../common/pond_colour.dart';

/// The report as an A4 PDF, in [l10n]'s language, to share through any app
/// without the server (SPEC F8). It reads like the screen (docs/design.md
/// §Step 6): by topic, alerts as bands, the worst pond first, compact
/// lines, a small square of each pond's colour from [pondColours], and the
/// word *estimé* where the screen writes ≈. Photos come from [photoBytes];
/// one that isn't on this phone, or can't be read, is left out.
Future<Uint8List> buildReportPdf(
  ReportContent content,
  AppLocalizations l10n,
  Locale locale, {
  Future<Uint8List?> Function(String photoKey)? photoBytes,
  required pw.Font regular,
  required pw.Font bold,
  List<pw.Font> fallback = const [],
  pw.Font? symbols,
  Map<String, PondColour> pondColours = const {},
}) async {
  final c = content;
  final h = c.header;
  final photos = <String, pw.ImageProvider>{};
  for (final key in c.photoKeys) {
    try {
      final bytes = await photoBytes?.call(key);
      if (bytes != null) photos[key] = pw.MemoryImage(bytes);
    } catch (_) {
      // Missing or unreadable: the report goes out without it.
    }
  }

  PdfColor pdf(Color colour) => PdfColor.fromInt(colour.toARGB32());
  const t = DoboColors.standard;
  final ink = pdf(t.ink);
  final muted = pdf(t.inkMuted);
  final danger = pdf(t.danger);
  final warning = pdf(t.warning);

  String code(String? id) => c.pondCodes[id] ?? '';
  String batch(String? id) => c.batchCodes[id] ?? '?';
  String estimated(String text) => '$text (${l10n.estimated})';
  int byCode(String? a, String? b) => code(a).compareTo(code(b));

  const codeColumn = 44.0;
  const lineGap = pw.EdgeInsets.symmetric(vertical: 2);

  /// The pond's code after a small square of its colour (none if unknown).
  pw.Widget pondCell(String? pondId, {PdfColor? textColour}) {
    if (pondId == null) return pw.SizedBox(width: codeColumn);
    final colour = pondColours[pondId];
    return pw.SizedBox(
      width: codeColumn,
      child: pw.Row(
        children: [
          if (colour != null) ...[
            pw.Container(
              width: 7,
              height: 7,
              decoration: pw.BoxDecoration(
                color: pdf(pondColourValue(colour)),
                border: textColour == null
                    ? null
                    : pw.Border.all(color: textColour, width: 0.5),
              ),
            ),
            pw.SizedBox(width: 3),
          ],
          pw.Text(
            code(pondId),
            style: pw.TextStyle(font: bold, color: textColour ?? ink),
          ),
        ],
      ),
    );
  }

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
    child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 13)),
  );
  pw.Widget empty(String text) =>
      pw.Text(text, style: pw.TextStyle(color: muted));

  /// A line about a pond: its code, an optional mark, the text.
  pw.Widget line(
    String text, {
    String? pondId,
    String? mark,
    PdfColor? markColour,
    pw.TextStyle? style,
  }) => pw.Padding(
    padding: lineGap,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pondCell(pondId),
        if (mark != null)
          pw.SizedBox(
            width: 12,
            child: pw.Text(
              mark,
              style: pw.TextStyle(font: bold, color: markColour),
            ),
          ),
        pw.Expanded(child: pw.Text(text, style: style)),
      ],
    ),
  );

  /// A line under a pond's line.
  pw.Widget sub(String text, {String? mark, PdfColor? markColour}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: codeColumn, bottom: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (mark != null)
              pw.SizedBox(
                width: 12,
                child: pw.Text(
                  mark,
                  style: pw.TextStyle(font: bold, color: markColour),
                ),
              ),
            pw.Expanded(child: pw.Text(text)),
          ],
        ),
      );

  /// An alert as a band: danger filled with white text, warning pale with
  /// a dark edge (docs/design.md: severity is a shape).
  pw.Widget band(String text, {required bool isDanger, String? pondId}) {
    final textColour = isDanger ? PdfColors.white : ink;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2),
      padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 4),
      decoration: pw.BoxDecoration(
        color: isDanger ? danger : pdf(t.warningFill),
        border: isDanger
            ? null
            : pw.Border(left: pw.BorderSide(color: warning, width: 3)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pondCell(pondId, textColour: textColour),
          pw.SizedBox(
            width: 12,
            child: pw.Text(
              '!',
              style: pw.TextStyle(
                font: bold,
                color: isDanger ? textColour : warning,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(font: bold, color: textColour),
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> photoRows(List<String> keys) {
    final present = [for (final k in keys) ?photos[k]];
    return [
      for (var i = 0; i < present.length; i += 2)
        pw.Padding(
          padding: const pw.EdgeInsets.only(
            left: codeColumn,
            top: 4,
            bottom: 4,
          ),
          child: pw.Row(
            children: [
              for (final img in present.skip(i).take(2))
                pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 8),
                  child: pw.Image(img, width: 220, height: 165),
                ),
            ],
          ),
        ),
    ];
  }

  String actions(Set<HealthAction> a) =>
      [for (final x in a) l10n.healthAction(x)].join(', ');

  String deaths(PondHealth ph) {
    final n = l10n.reportDeaths(formatCount(ph.deaths, locale));
    if (ph.byObserver.isEmpty) return n;
    return l10n.reportDeathsBy(
      n,
      [
        for (final o in ph.byObserver)
          l10n.reportObserverDeaths(
            o.name ?? l10n.reportUnknownPerson,
            formatCount(o.deaths, locale),
          ),
      ].join(', '),
    );
  }

  String fcr(BatchGrowth g) {
    final value = switch (g.fcrNote) {
      FcrNote.shared => '— (${l10n.reportFcrShared})',
      FcrNote.noSample => '— (${l10n.reportFcrNoSample})',
      FcrNote.stalled => l10n.fcrStalled,
      null => formatDecimal(g.fcr!, locale, decimals: 2),
    };
    final trend = switch (g.trend) {
      FcrTrend.worse => ' (${l10n.reportTrendWorse})',
      FcrTrend.better => ' (${l10n.reportTrendBetter})',
      FcrTrend.same => ' (${l10n.reportTrendSame})',
      null => '',
    };
    return [
      l10n.fcrValue('$value$trend'),
      if (g.survival != null)
        l10n.survivalValue(
          formatDecimal(g.survival! * 100, locale, decimals: 0),
        ),
    ].join(', ');
  }

  final split = splitObservations(c.observations, c.pondCodes);
  final water = [...c.water]..sort((a, b) => byCode(a.pondId, b.pondId));
  final feed = [...c.feed]..sort((a, b) => byCode(a.pondId, b.pondId));
  final growth = [...c.growth]
    ..sort((a, b) {
      final p = byCode(a.pondId, b.pondId);
      return p != 0 ? p : batch(a.batchId).compareTo(batch(b.batchId));
    });

  final doc = pw.Document(
    theme: pdfTheme(
      regular: regular,
      bold: bold,
      fallback: fallback,
      symbols: symbols,
    ),
    title: l10n.reportTitle,
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          [
            'Dobo',
            h.siteName,
            formatDate(h.visitDay),
            '${context.pageNumber}/${context.pagesCount}',
          ].join(' · '),
          style: pw.TextStyle(fontSize: 8, color: muted),
        ),
      ),
      build: (context) => [
        pw.Text(
          l10n.reportTitle,
          style: pw.TextStyle(font: bold, fontSize: 18),
        ),
        pw.Text(
          l10n.reportHeaderTitle(h.siteName, formatDate(h.visitDay)),
          style: pw.TextStyle(font: bold, fontSize: 13),
        ),
        if (h.memberName.isNotEmpty)
          pw.Text(
            h.groupName == null
                ? l10n.reportAuthor(h.memberName)
                : l10n.reportAuthorGroup(h.memberName, h.groupName!),
          ),
        pw.Text(
          l10n.reportPeriod(formatDate(h.periodFrom), formatDate(h.periodTo)),
        ),
        pw.Text(
          l10n.reportPublishedOn(formatDate(h.builtAt)),
          style: pw.TextStyle(color: muted),
        ),

        heading(l10n.reportSummary),
        c.summary == null ? empty(l10n.reportNoSummary) : pw.Text(c.summary!),

        heading(l10n.reportAlerts),
        if (c.alerts.isEmpty) empty(l10n.reportAlertsNone),
        for (final a in c.alerts)
          band(
            l10n.alertText(a, batchCode: c.batchCodes[a.batchId]),
            isDanger: a.severity == Severity.danger,
            pondId: a.pondId,
          ),

        heading(l10n.reportHealth),
        if (c.health.isEmpty) empty(l10n.reportHealthNone),
        for (final ph in orderHealth(c.health, c.pondCodes)) ...[
          line(deaths(ph), pondId: ph.pondId),
          for (final e in healthEntries(ph))
            ...switch (e) {
              SignsEntry(:final signs) => [
                sub(
                  l10n.reportSigns(
                    formatDate(signs.date),
                    signs.signs.map(l10n.warningSign).join(', '),
                  ),
                  mark: '!',
                  markColour: danger,
                ),
              ],
              EventEntry(:final event) => [
                sub(
                  l10n.reportHealthEventLine(
                    formatDate(event.at),
                    [
                      if (event.signs.isNotEmpty)
                        event.signs.map(l10n.warningSign).join(', '),
                      ?event.suspectedIssue,
                      if (event.actions.isNotEmpty) actions(event.actions),
                    ].join(', '),
                  ),
                  mark: '!',
                  markColour: danger,
                ),
                ...photoRows(event.photoKeys),
              ],
              TreatmentEntry(:final treatment) => [
                sub(
                  l10n.reportTreatmentLine(
                    formatDate(treatment.at),
                    treatment.product,
                    treatment.dose,
                  ),
                  mark: '+',
                ),
              ],
            },
        ],

        heading(l10n.reportWater),
        if (water.isEmpty) empty(l10n.reportNoFish),
        for (final w in water)
          if (w.at == null)
            line(l10n.reportNoReading, pondId: w.pondId)
          else
            pw.Padding(
              padding: lineGap,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pondCell(w.pondId),
                  pw.Expanded(
                    child: pw.Wrap(
                      spacing: 10,
                      children: [
                        pw.Text(formatDate(w.at!)),
                        for (final (param, text) in [
                          if (w.temperatureC != null)
                            (
                              WaterParam.temperature,
                              '${formatNumber(w.temperatureC!, locale)} °C',
                            ),
                          if (w.ph != null)
                            (
                              WaterParam.ph,
                              'pH ${formatNumber(w.ph!, locale)}',
                            ),
                          if (w.oxygenMgL != null)
                            (
                              WaterParam.oxygen,
                              'O₂ ${formatNumber(w.oxygenMgL!, locale)} mg/L',
                            ),
                          if (w.colour != null)
                            (WaterParam.colour, l10n.waterColour(w.colour!)),
                        ])
                          switch ([
                            for (final i in w.issues)
                              if (i.param == param) i.severity,
                          ].firstOrNull) {
                            null => pw.Text(text),
                            final s => pw.Text(
                              '! $text',
                              style: pw.TextStyle(
                                font: bold,
                                color: s == Severity.danger ? danger : warning,
                              ),
                            ),
                          },
                      ],
                    ),
                  ),
                ],
              ),
            ),

        heading(l10n.reportGrowth),
        if (growth.isEmpty) empty(l10n.reportNoFish),
        for (final g in growth) ...[
          line(
            [
              l10n.reportGrowthLine(
                batch(g.batchId),
                formatGrams(g.avgWeightG, locale),
                formatDate(g.weighedOn),
              ),
              estimated(formatKg(g.biomassG, locale)),
              estimated(l10n.pondFishCount(formatCount(g.liveCount, locale))),
            ].join(', '),
            pondId: g.pondId,
          ),
          sub(fcr(g)),
        ],

        heading(l10n.reportFeed),
        if (feed.isEmpty) empty(l10n.reportNoFeed),
        for (final f in feed)
          pw.Padding(
            padding: lineGap,
            child: pw.Row(
              children: [
                pondCell(f.pondId),
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    formatKg(f.feedG, locale),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        if (feed.isNotEmpty)
          pw.Padding(
            padding: lineGap,
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: codeColumn,
                  child: pw.Text(
                    l10n.reportFeedTotal,
                    style: pw.TextStyle(font: bold),
                  ),
                ),
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    formatKg(c.feedTotalG, locale),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(font: bold),
                  ),
                ),
              ],
            ),
          ),
        for (final text in l10n.reportFeedStockLines(c.feedStock, locale))
          c.feedStock == null ? empty(text) : pw.Text(text),

        heading(l10n.reportNext),
        if (c.next.isEmpty) empty(l10n.reportNextNone),
        for (final n in c.next)
          line(
            l10n.labelValue(
              formatDate(n.date),
              l10n.reportNextText(
                n,
                pond: code(n.pondId),
                batch: batch(n.batchId),
              ),
            ),
            pondId: n.pondId,
          ),

        heading(l10n.reportObservations),
        if (split.problems.isEmpty &&
            split.notes.isEmpty &&
            split.inOrder.isEmpty &&
            c.visitPhotoKeys.isEmpty)
          empty(l10n.reportObservationsNone),
        for (final o in [...split.problems, ...split.notes]) ...[
          line(
            o.note == null
                ? l10n.observationCategory(o.category)
                : l10n.labelValue(
                    l10n.observationCategory(o.category),
                    o.note!,
                  ),
            pondId: o.pondId,
            mark: o.ok == false ? '!' : null,
            markColour: warning,
          ),
          ...photoRows(o.photoKeys),
        ],
        if (split.inOrder.isNotEmpty)
          pw.Padding(
            padding: lineGap,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(width: codeColumn),
                // A drawn tick: none of the bundled fonts has ✓.
                pw.SizedBox(
                  width: 12,
                  child: pw.SvgImage(
                    svg:
                        '<svg xmlns="http://www.w3.org/2000/svg" '
                        'viewBox="0 0 24 24"><path fill="#${t.ok.toARGB32().toRadixString(16).substring(2)}" '
                        'd="M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z"/></svg>',
                    width: 9,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(l10n.reportInOrder(split.inOrder.join(', '))),
                ),
              ],
            ),
          ),
        ...photoRows(c.visitPhotoKeys),
      ],
    ),
  );
  return doc.save();
}
