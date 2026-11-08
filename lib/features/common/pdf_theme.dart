import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

/// The PDFs' fonts: Noto Sans, and a Noto Sans Math subset for the arrows
/// and signs Noto Sans lacks (→, ≥, ≈).
pw.ThemeData pdfTheme({
  required pw.Font regular,
  required pw.Font bold,
  pw.Font? symbols,
}) =>
    pw.ThemeData.withFont(base: regular, bold: bold, fontFallback: [?symbols]);

/// The PDF fonts' files, which can be sent to a background isolate (a
/// `pw.Font` can't).
typedef PdfFontData = ({ByteData regular, ByteData bold, ByteData symbols});

/// [data] as fonts, in the isolate that lays out the PDF.
({pw.Font regular, pw.Font bold, pw.Font symbols}) pdfFontsFrom(
  PdfFontData data,
) => (
  regular: pw.Font.ttf(data.regular),
  bold: pw.Font.ttf(data.bold),
  symbols: pw.Font.ttf(data.symbols),
);
