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

/// [data] as fonts, in the isolate that lays out the PDF.
({pw.Font regular, pw.Font bold, pw.Font symbols}) pdfFontsFrom(
  PdfFontData data,
) => (
  regular: pw.Font.ttf(data.regular),
  bold: pw.Font.ttf(data.bold),
  symbols: pw.Font.ttf(data.symbols),
);
