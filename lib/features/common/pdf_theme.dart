import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

/// The PDFs' fonts: [regular] and [bold], then [fallback] fonts in order,
/// then [symbols] (a Noto Sans Math subset for the arrows and signs the
/// text fonts lack: →, ≥, ≈).
pw.ThemeData pdfTheme({
  required pw.Font regular,
  required pw.Font bold,
  List<pw.Font> fallback = const [],
  pw.Font? symbols,
}) => pw.ThemeData.withFont(
  base: regular,
  bold: bold,
  fontFallback: [...fallback, ?symbols],
);

/// The PDF fonts' files, which can be sent to a background isolate (a
/// `pw.Font` can't).
typedef PdfFontData = ({ByteData regular, ByteData bold, ByteData symbols});

/// The app's PDF fonts' files (docs/design.md §Step 6): Atkinson, with Noto
/// Sans then its symbols for the glyphs Atkinson lacks.
typedef AppPdfFontData = ({
  ByteData regular,
  ByteData bold,
  ByteData fallback,
  ByteData symbols,
});

/// [data] as fonts, in the isolate that lays out the PDF.
({pw.Font regular, pw.Font bold, pw.Font fallback, pw.Font symbols})
appPdfFontsFrom(AppPdfFontData data) => (
  regular: pw.Font.ttf(data.regular),
  bold: pw.Font.ttf(data.bold),
  fallback: pw.Font.ttf(data.fallback),
  symbols: pw.Font.ttf(data.symbols),
);

/// [data] as fonts, in the isolate that lays out the PDF.
({pw.Font regular, pw.Font bold, pw.Font symbols}) pdfFontsFrom(
  PdfFontData data,
) => (
  regular: pw.Font.ttf(data.regular),
  bold: pw.Font.ttf(data.bold),
  symbols: pw.Font.ttf(data.symbols),
);
