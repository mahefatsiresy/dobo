import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Color, Locale;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../common/pictogram_paths.dart';
import '../common/pictograms.dart';
import '../common/pond_colour.dart';
import '../transcription/week.dart';
import '../common/pdf_theme.dart';

/// A pond as its paper sheet shows it: the code painted on its stake, on
/// its colour.
class PaperPond {
  const PaperPond({required this.code, required this.colour});

  final String code;
  final PondColour colour;
}

/// One printed page: a pond's week.
class PaperPage {
  const PaperPage(this.pond, this.days);

  final PaperPond pond;

  /// Monday to Sunday, date-only.
  final List<DateTime> days;
}

/// The pages for [weeks] weeks from the week holding [firstWeek]: week by
/// week, and within a week the ponds in [ponds]' order (plan M8 Decision 3).
List<PaperPage> paperPages(
  List<PaperPond> ponds,
  DateTime firstWeek,
  int weeks,
) {
  final monday = weekOf(firstWeek).first;
  return [
    for (var w = 0; w < weeks; w++)
      for (final pond in ponds)
        PaperPage(
          pond,
          weekOf(DateTime(monday.year, monday.month, monday.day + 7 * w)),
        ),
  ];
}

/// Malagasy first, then French: workers read the first, members the second.
String _both(String mg, String fr) => mg == fr ? mg : '$mg / $fr';

String _day(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

/// "Herinandro 09/11/2026 – 15/11/2026 / Semaine du 09/11/2026 au …".
String paperWeekLabel(
  List<DateTime> days,
  AppLocalizations mg,
  AppLocalizations fr,
) => _both(
  mg.paperWeek(_day(days.first), _day(days.last)),
  fr.paperWeek(_day(days.first), _day(days.last)),
);

/// Every label the sheet prints, as "mg / fr".
List<String> paperSheetLabels(AppLocalizations mg, AppLocalizations fr) => [
  _both(mg.paperTitle, fr.paperTitle),
  _both(mg.paperWorker, fr.paperWorker),
  _both(mg.paperDay, fr.paperDay),
  _both(mg.paperFeedKg, fr.paperFeedKg),
  _both(mg.deaths, fr.deaths),
  _both(mg.leftovers, fr.leftovers),
  _both(mg.signsSeen, fr.signsSeen),
  _both(mg.waterColourLabel, fr.waterColourLabel),
  _both(mg.paperHowTo, fr.paperHowTo),
  for (final l in Leftover.values) _both(mg.leftover(l), fr.leftover(l)),
  for (final s in WarningSign.values)
    _both(mg.warningSign(s), fr.warningSign(s)),
  for (final c in WaterColour.values)
    _both(mg.waterColour(c), fr.waterColour(c)),
];

/// `fiches-<Monday of [firstWeek]'s week>.pdf`.
String paperFileName(DateTime firstWeek) {
  final m = weekOf(firstWeek).first;
  return 'fiches-${DateFormat('yyyy-MM-dd').format(m)}.pdf';
}

PdfColor _pdfColour(Color c) => PdfColor.fromInt(c.toARGB32());

// Column widths in points; they fit A4 landscape less 24 pt margins (794).
const _dayW = 100.0;
const _feedW = 80.0;
const _deathsW = 56.0;
const _tickW = 26.0;
const _rowH = 44.0;
const _line = PdfColors.grey600;

/// Blank weekly sheets, one A4 landscape page per pond per week, laid out
/// like the daily log and copied into the transcription grid (SPEC F13,
/// plan M8 Decision 2).
Future<Uint8List> buildPaperSheetPdf({
  required List<PaperPond> ponds,
  required DateTime firstWeek,
  int weeks = 1,
  required pw.Font regular,
  required pw.Font bold,
  pw.Font? symbols,
}) {
  final mg = lookupAppLocalizations(const Locale('mg'));
  final fr = lookupAppLocalizations(const Locale('fr'));
  final doc = pw.Document(
    theme: pdfTheme(regular: regular, bold: bold, symbols: symbols),
    title: _both(mg.paperTitle, fr.paperTitle),
  );
  const format = PdfPageFormat(
    842,
    595,
    marginAll: 24,
  ); // A4 landscape, in points.
  final pages = paperPages(ponds, firstWeek, weeks);
  if (pages.isEmpty) {
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (_) => pw.Text(_both(mg.paperNoPonds, fr.paperNoPonds)),
      ),
    );
  }
  for (final page in pages) {
    doc.addPage(
      pw.Page(pageFormat: format, build: (_) => _sheet(page, mg, fr, bold)),
    );
  }
  return doc.save();
}

/// [buildPaperSheetPdf] in a background isolate, so the screen doesn't
/// freeze while several weeks of pages are laid out.
Future<Uint8List> buildPaperSheetPdfInBackground({
  required List<PaperPond> ponds,
  required DateTime firstWeek,
  int weeks = 1,
  required PdfFontData fonts,
}) => Isolate.run(() {
  final f = pdfFontsFrom(fonts);
  return buildPaperSheetPdf(
    ponds: ponds,
    firstWeek: firstWeek,
    weeks: weeks,
    regular: f.regular,
    bold: f.bold,
    symbols: f.symbols,
  );
});

// Pictogram columns, numbered 1… left to right; the legend uses the numbers.
List<(int, pw.Widget, String)> _pictograms(
  AppLocalizations mg,
  AppLocalizations fr,
  double size,
) {
  var n = 0;
  pw.Widget icon(String path) =>
      pw.SvgImage(svg: pictogramSvg(path), width: size, height: size);
  return [
    for (final l in Leftover.values)
      (++n, icon(leftoverPath(l)), _both(mg.leftover(l), fr.leftover(l))),
    for (final s in WarningSign.values)
      (
        ++n,
        icon(warningSignPath(s)),
        _both(mg.warningSign(s), fr.warningSign(s)),
      ),
    for (final c in WaterColour.values)
      (
        ++n,
        pw.Container(
          width: size,
          height: size,
          decoration: pw.BoxDecoration(
            color: _pdfColour(waterColourValue(c)),
            border: pw.Border.all(color: _line, width: 0.5),
          ),
        ),
        _both(mg.waterColour(c), fr.waterColour(c)),
      ),
  ];
}

pw.Widget _sheet(
  PaperPage page,
  AppLocalizations mg,
  AppLocalizations fr,
  pw.Font bold,
) {
  final small = const pw.TextStyle(fontSize: 7);
  final header = pw.TextStyle(font: bold, fontSize: 8);
  final background = pondColourValue(page.pond.colour);
  final light = background.computeLuminance() > 0.4;
  final pictos = _pictograms(mg, fr, 16);
  final legendIcons = _pictograms(mg, fr, 9);

  pw.Widget box(double width, double height, pw.Widget child) => pw.Container(
    width: width,
    height: height,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line, width: 0.5),
    ),
    child: child,
  );
  pw.Widget tick() => pw.Container(
    width: 13,
    height: 13,
    decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
  );
  pw.Widget group(String label, int count) => box(
    _tickW * count,
    16,
    pw.Text(label, style: header, textAlign: pw.TextAlign.center),
  );

  final leftovers = Leftover.values.length;
  final signs = WarningSign.values.length;
  final colours = WaterColour.values.length;
  final dayLabel = DateFormat('dd/MM');

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          pw.Container(
            width: 84,
            height: 44,
            alignment: pw.Alignment.center,
            color: _pdfColour(background),
            child: pw.Text(
              page.pond.code,
              style: pw.TextStyle(
                font: bold,
                fontSize: 28,
                color: light ? PdfColors.black : PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _both(mg.paperTitle, fr.paperTitle),
                  style: pw.TextStyle(font: bold, fontSize: 14),
                ),
                pw.Text(paperWeekLabel(page.days, mg, fr)),
              ],
            ),
          ),
          pw.Text('${_both(mg.paperWorker, fr.paperWorker)} : '),
          pw.Container(
            width: 180,
            height: 20,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.8)),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      // Group headings over the pictogram columns.
      pw.Row(
        children: [
          pw.SizedBox(width: _dayW + _feedW + _deathsW),
          group(_both(mg.leftovers, fr.leftovers), leftovers),
          group(_both(mg.signsSeen, fr.signsSeen), signs),
          group(_both(mg.waterColourLabel, fr.waterColourLabel), colours),
        ],
      ),
      // Column headings: labels, then each pictogram with its number.
      pw.Row(
        children: [
          box(
            _dayW,
            40,
            pw.Text(_both(mg.paperDay, fr.paperDay), style: header),
          ),
          box(
            _feedW,
            40,
            pw.Text(
              _both(mg.paperFeedKg, fr.paperFeedKg),
              style: header,
              textAlign: pw.TextAlign.center,
            ),
          ),
          box(
            _deathsW,
            40,
            pw.Text(
              _both(mg.deaths, fr.deaths),
              style: header,
              textAlign: pw.TextAlign.center,
            ),
          ),
          for (final (n, icon, _) in pictos)
            box(
              _tickW,
              40,
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  icon,
                  pw.Text('$n', style: small),
                ],
              ),
            ),
        ],
      ),
      for (final d in page.days)
        pw.Row(
          children: [
            box(
              _dayW,
              _rowH,
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(mg.weekday(d.weekday), style: header),
                  pw.Text(
                    '${fr.weekday(d.weekday)} ${dayLabel.format(d)}',
                    style: small,
                  ),
                ],
              ),
            ),
            box(_feedW, _rowH, pw.SizedBox()),
            box(_deathsW, _rowH, pw.SizedBox()),
            for (var i = 0; i < pictos.length; i++) box(_tickW, _rowH, tick()),
          ],
        ),
      pw.SizedBox(height: 8),
      pw.Text(_both(mg.paperHowTo, fr.paperHowTo), style: header),
      pw.SizedBox(height: 4),
      pw.Wrap(
        spacing: 6,
        runSpacing: 2,
        children: [
          for (final (n, icon, label) in legendIcons)
            pw.SizedBox(
              width: 255,
              child: pw.Row(
                children: [
                  pw.SizedBox(width: 14, child: pw.Text('$n', style: header)),
                  icon,
                  pw.SizedBox(width: 4),
                  pw.Expanded(child: pw.Text(label, style: small)),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}
