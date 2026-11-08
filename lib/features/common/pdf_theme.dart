import 'package:pdf/widgets.dart' as pw;

/// The PDFs' fonts: Noto Sans, and a Noto Sans Math subset for the arrows
/// and signs Noto Sans lacks (→, ≥, ≈).
pw.ThemeData pdfTheme({
  required pw.Font regular,
  required pw.Font bold,
  pw.Font? symbols,
}) =>
    pw.ThemeData.withFont(base: regular, bold: bold, fontFallback: [?symbols]);
