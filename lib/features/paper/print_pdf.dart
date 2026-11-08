import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Sends a PDF to the phone's print service, named [name].
typedef PdfPrinter = Future<void> Function(String name, Uint8List bytes);

/// Android's print dialog (a printer, or "Save as PDF"), set to A4
/// landscape like the paper sheets; tests replace it.
final pdfPrinterProvider = Provider<PdfPrinter>(
  (ref) => (name, bytes) async {
    await Printing.layoutPdf(
      name: name,
      format: PdfPageFormat.a4.landscape,
      onLayout: (_) async => bytes,
    );
  },
);
