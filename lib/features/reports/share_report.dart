import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../sync/providers.dart';
import '../../domain/report/report_content.dart';
import '../../l10n/app_localizations.dart';
import '../common/file_slug.dart';
import '../sync/backup_actions.dart' show backupDirProvider;
import 'report_pdf.dart';

/// Opens the share sheet for a written file.
typedef ReportSharer = Future<void> Function(File file);

final reportSharerProvider = Provider<ReportSharer>(
  (ref) => (file) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  },
);

/// Where a report's photo files are, by key; null when not on this phone.
typedef PhotoBytes = Future<Uint8List?> Function(String photoKey);

final reportPhotoBytesProvider = Provider<PhotoBytes>((ref) {
  final files = ref.watch(photoFilesProvider);
  final store = ref.watch(photoStoreProvider);
  final associationId = ref.watch(sessionProvider).requireValue!.associationId;
  // Downloads a sent photo not yet on this phone, when online.
  return (key) async => (await files.fetch(
    key,
    associationId: associationId,
    store: store,
  ))?.readAsBytes();
});

/// Builds [content]'s PDF in the phone's language and shares it through any
/// app, with no server (SPEC F8).
Future<void> shareReport(
  BuildContext context,
  WidgetRef ref,
  ReportContent content,
) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context);
  final photoBytes = ref.read(reportPhotoBytesProvider);
  final sharer = ref.read(reportSharerProvider);
  final dirOf = ref.read(backupDirProvider);
  final fonts = await pdfFonts();
  final bytes = await buildReportPdf(
    content,
    l10n,
    locale,
    photoBytes: photoBytes,
    regular: fonts.regular,
    bold: fonts.bold,
    symbols: fonts.symbols,
  );
  final file = File('${(await dirOf()).path}/${reportFileName(content)}');
  await file.writeAsBytes(bytes, flush: true);
  await sharer(file);
}

/// `rapport-<site>-<yyyy-mm-dd>.pdf`, safe on any file system.
String reportFileName(ReportContent c) {
  final day = farmDate(c.header.visitDay);
  String two(int n) => n.toString().padLeft(2, '0');
  return 'rapport-${fileSlug(c.header.siteName, 'site')}-'
      '${day.year}-${two(day.month)}-${two(day.day)}.pdf';
}

Future<pw.Font> _font(String asset) async =>
    pw.Font.ttf(await rootBundle.load(asset));

/// The PDF fonts: Noto Sans regular and bold, and the symbols they lack.
typedef PdfFonts = ({pw.Font regular, pw.Font bold, pw.Font symbols});

Future<PdfFonts> pdfFonts() async => (
  regular: await _font('assets/fonts/NotoSans-Regular.ttf'),
  bold: await _font('assets/fonts/NotoSans-Bold.ttf'),
  symbols: await _font('assets/fonts/NotoSansMath-Symbols.ttf'),
);

/// Writes [bytes] as [fileName] and opens the share sheet.
Future<void> sharePdfFile(
  WidgetRef ref,
  String fileName,
  Uint8List bytes,
) async {
  final sharer = ref.read(reportSharerProvider);
  final dirOf = ref.read(backupDirProvider);
  final file = File('${(await dirOf()).path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await sharer(file);
}
