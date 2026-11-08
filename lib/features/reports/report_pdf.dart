import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/growth.dart';
import '../../domain/report/report_content.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/pdf_theme.dart';

/// The report as an A4 PDF, in [l10n]'s language, to share through any app
/// without the server (SPEC F8). Photos come from [photoBytes]; one that
/// isn't on this phone, or can't be read, is left out.
Future<Uint8List> buildReportPdf(
  ReportContent content,
  AppLocalizations l10n,
  Locale locale, {
  Future<Uint8List?> Function(String photoKey)? photoBytes,
  required pw.Font regular,
  required pw.Font bold,
  pw.Font? symbols,
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

  String pond(String? id) => c.pondCodes[id] ?? '';
  String batch(String? id) => c.batchCodes[id] ?? '?';
  String estimated(String text) => '$text (${l10n.estimated})';

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
    child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 13)),
  );
  pw.Widget empty(String text) =>
      pw.Text(text, style: const pw.TextStyle(color: PdfColors.grey700));
  pw.Widget line(String text, {String? pondCode, bool alert = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 32,
              child: pw.Text(pondCode ?? '', style: pw.TextStyle(font: bold)),
            ),
            pw.Expanded(
              child: pw.Text(
                text,
                style: alert
                    ? pw.TextStyle(font: bold, color: PdfColors.red800)
                    : null,
              ),
            ),
          ],
        ),
      );
  pw.Widget indented(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(left: 32, bottom: 1),
    child: pw.Text(text),
  );
  List<pw.Widget> photoRows(List<String> keys) {
    final present = [for (final k in keys) ?photos[k]];
    return [
      for (var i = 0; i < present.length; i += 2)
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 32, top: 4, bottom: 4),
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

  String actions(Set<HealthAction> a) => [
    for (final x in a)
      switch (x) {
        HealthAction.isolated => l10n.actionIsolated,
        HealthAction.technicianCalled => l10n.actionTechnician,
        HealthAction.released => l10n.actionReleased,
      },
  ].join(', ');

  final doc = pw.Document(
    theme: pdfTheme(regular: regular, bold: bold, symbols: symbols),
    title: l10n.reportTitle,
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Text(
              l10n.labelValue(h.siteName, formatDate(h.visitDay)),
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(color: PdfColors.grey700),
        ),
      ),
      build: (context) => [
        pw.Text(
          l10n.reportTitle,
          style: pw.TextStyle(font: bold, fontSize: 18),
        ),
        pw.Text(
          l10n.labelValue(h.siteName, formatDate(h.visitDay)),
          style: const pw.TextStyle(fontSize: 13),
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
        pw.Text(l10n.reportPublishedOn(formatDate(h.builtAt))),

        heading(l10n.reportSummary),
        c.summary == null ? empty(l10n.reportNoSummary) : pw.Text(c.summary!),

        heading(l10n.reportAlerts),
        if (c.alerts.isEmpty) empty(l10n.reportNothing),
        for (final a in c.alerts)
          line(
            l10n.alertText(a, batchCode: c.batchCodes[a.batchId]),
            pondCode: pond(a.pondId),
            alert: a.severity == Severity.danger,
          ),

        heading(l10n.reportHealth),
        if (c.health.isEmpty) empty(l10n.reportNothing),
        for (final ph in c.health) ...[
          line(
            l10n.reportDeaths(formatCount(ph.deaths, locale)),
            pondCode: pond(ph.pondId),
          ),
          if (ph.byObserver.isNotEmpty)
            indented(
              [
                for (final o in ph.byObserver)
                  l10n.reportObserverDeaths(
                    o.name ?? l10n.reportUnknownPerson,
                    formatCount(o.deaths, locale),
                  ),
              ].join(l10n.reportListSeparator),
            ),
          for (final s in ph.signs)
            indented(
              l10n.reportSigns(
                formatDate(s.date),
                s.signs.map(l10n.warningSign).join(', '),
              ),
            ),
          for (final e in ph.events) ...[
            indented(
              l10n.reportHealthEventLine(
                formatDate(e.at),
                [
                  if (e.signs.isNotEmpty)
                    e.signs.map(l10n.warningSign).join(', '),
                  ?e.suspectedIssue,
                  if (e.actions.isNotEmpty) actions(e.actions),
                ].join(' — '),
              ),
            ),
            ...photoRows(e.photoKeys),
          ],
          for (final t in ph.treatments)
            indented(
              l10n.reportTreatmentLine(formatDate(t.at), t.product, t.dose),
            ),
        ],

        heading(l10n.reportWater),
        if (c.water.isEmpty) empty(l10n.reportNoFish),
        for (final w in c.water)
          if (w.at == null)
            line(l10n.reportNoReading, pondCode: pond(w.pondId))
          else ...[
            line(
              l10n.reportReadingOn(formatDate(w.at!)),
              pondCode: pond(w.pondId),
              alert: w.issues.isNotEmpty,
            ),
            indented(
              [
                if (w.temperatureC != null)
                  l10n.labelValue(
                    l10n.temperature,
                    '${formatNumber(w.temperatureC!, locale)} °C',
                  ),
                if (w.ph != null)
                  l10n.labelValue(l10n.ph, formatNumber(w.ph!, locale)),
                if (w.oxygenMgL != null)
                  l10n.labelValue(
                    l10n.oxygen,
                    '${formatNumber(w.oxygenMgL!, locale)} mg/L',
                  ),
                if (w.colour != null) l10n.waterColour(w.colour!),
              ].join(l10n.reportListSeparator),
            ),
          ],

        heading(l10n.reportGrowth),
        if (c.growth.isEmpty) empty(l10n.reportNoFish),
        for (final g in c.growth) ...[
          line(
            l10n.reportGrowthLine(
              batch(g.batchId),
              formatGrams(g.avgWeightG, locale),
              formatDate(g.weighedOn),
            ),
            pondCode: pond(g.pondId),
          ),
          indented(
            estimated(
              l10n.labelValue(l10n.reportBiomass, formatKg(g.biomassG, locale)),
            ),
          ),
          indented(
            estimated(
              l10n.labelValue(
                l10n.reportFish,
                formatCount(g.liveCount, locale),
              ),
            ),
          ),
          indented(
            l10n.fcrValue(
              '${switch (g.fcrNote) {
                FcrNote.shared => '— (${l10n.reportFcrShared})',
                FcrNote.noSample => '— (${l10n.reportFcrNoSample})',
                FcrNote.stalled => l10n.fcrStalled,
                null => formatDecimal(g.fcr!, locale, decimals: 2),
              }}${switch (g.trend) {
                FcrTrend.worse => ' (${l10n.reportTrendWorse})',
                FcrTrend.better => ' (${l10n.reportTrendBetter})',
                FcrTrend.same => ' (${l10n.reportTrendSame})',
                null => '',
              }}',
            ),
          ),
          if (g.survival != null)
            indented(
              l10n.survivalValue(
                formatDecimal(g.survival! * 100, locale, decimals: 0),
              ),
            ),
        ],

        heading(l10n.reportFeed),
        if (c.feed.isEmpty) empty(l10n.reportNoFeed),
        for (final f in c.feed)
          line(formatKg(f.feedG, locale), pondCode: pond(f.pondId)),
        if (c.feed.isNotEmpty)
          line(
            l10n.labelValue(
              l10n.reportFeedTotal,
              formatKg(c.feedTotalG, locale),
            ),
          ),
        for (final text in l10n.reportFeedStockLines(c.feedStock, locale))
          c.feedStock == null ? empty(text) : line(text),

        heading(l10n.reportNext),
        if (c.next.isEmpty) empty(l10n.reportNothing),
        for (final n in c.next)
          line(
            l10n.labelValue(
              formatDate(n.date),
              l10n.reportNextText(
                n,
                pond: pond(n.pondId),
                batch: batch(n.batchId),
              ),
            ),
            pondCode: pond(n.pondId),
          ),

        heading(l10n.reportObservations),
        if (c.observations.isEmpty && c.visitPhotoKeys.isEmpty)
          empty(l10n.reportNothing),
        for (final o in c.observations.where((o) => o.ok != true)) ...[
          line(
            o.note == null
                ? l10n.observationCategory(o.category)
                : l10n.labelValue(
                    l10n.observationCategory(o.category),
                    o.note!,
                  ),
            pondCode: pond(o.pondId),
          ),
          ...photoRows(o.photoKeys),
        ],
        if (c.observations.any((o) => o.ok == true))
          line(
            l10n.reportAllOk(
              {
                for (final o in c.observations)
                  if (o.ok == true) l10n.observationCategory(o.category),
              }.join(', '),
            ),
          ),
        ...photoRows(c.visitPhotoKeys),
      ],
    ),
  );
  return doc.save();
}
