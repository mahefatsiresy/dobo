import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/dates.dart';
import '../common/file_slug.dart';
import 'export_tables.dart';
import '../common/pdf_theme.dart';

/// [t] as an A4 landscape PDF: title and period on the first page, the
/// header row repeated on every page, then the footer (SPEC F15).
Future<Uint8List> buildExportPdf(
  ExportTable t, {
  required pw.Font regular,
  required pw.Font bold,
  pw.Font? symbols,
}) {
  final doc = pw.Document(
    theme: pdfTheme(regular: regular, bold: bold, symbols: symbols),
    title: t.title,
  );
  const cell = pw.TextStyle(fontSize: 8);
  final head = pw.TextStyle(font: bold, fontSize: 8);
  // The last column (observations or weights) takes what's left.
  final widths = <int, pw.TableColumnWidth>{
    for (var i = 0; i < t.header.length - 1; i++)
      i: const pw.IntrinsicColumnWidth(flex: 1),
    t.header.length - 1: const pw.FlexColumnWidth(3),
  };
  final rows = t.rows.isEmpty
      ? [
          [t.nothing, for (var i = 1; i < t.header.length; i++) ''],
        ]
      : t.rows;
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      // A year of daily logs for a few ponds runs to some 50 pages.
      maxPages: 1000,
      margin: const pw.EdgeInsets.all(28),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Text(t.title, style: pw.TextStyle(font: bold, fontSize: 16)),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, bottom: 10),
          child: pw.Text(t.period),
        ),
        pw.TableHelper.fromTextArray(
          headers: t.header,
          data: rows,
          headerCount: 1,
          columnWidths: widths,
          headerStyle: head,
          cellStyle: cell,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 2,
          ),
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
        ),
        if (t.footer != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(t.footer!, style: cell),
          ),
      ],
    ),
  );
  return doc.save();
}

/// `<kind>-<site>-<from>-<to>.<ext>`, with [kind] `registre` or
/// `suivi-hebdo` (plan M8 Decision 11).
String exportFileName(
  String kind,
  String site,
  DateTime from,
  DateTime to,
  String ext,
) {
  final day = DateFormat('yyyy-MM-dd');
  return '$kind-${fileSlug(site, 'site')}-'
      '${day.format(farmDate(from))}-${day.format(farmDate(to))}.$ext';
}
