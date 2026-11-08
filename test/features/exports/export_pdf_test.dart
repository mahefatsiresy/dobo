import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/exports/register.dart';
import 'package:dobo/domain/exports/weekly.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/features/exports/export_pdf.dart';
import 'package:dobo/features/exports/export_tables.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import '../paper/paper_sheet_pdf_test.dart' show pageCount;

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));
  const fr = Locale('fr');
  pw.Font font(String name) => pw.Font.ttf(
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync()),
  );
  final regular = font('NotoSans-Regular.ttf');
  final bold = font('NotoSans-Bold.ttf');
  final symbols = font('NotoSansMath-Symbols.ttf');
  const names = ExportNames(
    site: 'Ferme Soa',
    ponds: {
      'e1': 'E1',
      'e2': 'E2',
      'e3': 'E3',
      'e4': 'E4',
      'e5': 'E5',
      'e6': 'E6',
    },
  );

  test('a year of register rows builds several pages', () async {
    final rows = [
      for (var day = 0; day < 365; day++)
        for (var p = 1; p <= 6; p++)
          LogRow(
            LogFact(
              id: '$day-$p',
              pondId: 'e$p',
              date: farmDateToUtc(DateTime(2026, 1, 1 + day)),
              feedG: 12000,
              note: 'Été « ok » ; ça va',
            ),
            const [],
          ),
    ];
    final table = registerTable(
      rows,
      names,
      l10n,
      fr,
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 12, 31),
    );
    final bytes = await buildExportPdf(
      table,
      regular: regular,
      bold: bold,
      symbols: symbols,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(pageCount(bytes), greaterThan(20));
  });

  test('both tables build as PDF, empty ones too', () async {
    final weekly = weeklyTable(
      [WeeklyRow(pondId: 'e1', weekStart: DateTime(2026, 3, 2), ph: 7)],
      names,
      DomainConfig.defaults,
      l10n,
      fr,
      from: DateTime(2026, 3, 2),
      to: DateTime(2026, 3, 8),
    );
    final empty = registerTable(
      const [],
      names,
      l10n,
      fr,
      from: DateTime(2026, 3, 1),
      to: DateTime(2026, 3, 31),
    );
    for (final t in [weekly, empty]) {
      final bytes = await buildExportPdf(
        t,
        regular: regular,
        bold: bold,
        symbols: symbols,
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(pageCount(bytes), 1);
    }
  });

  test('file names', () {
    expect(
      exportFileName(
        'registre',
        'Ferme Soa',
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 31),
        'csv',
      ),
      'registre-Ferme-Soa-2026-10-01-2026-10-31.csv',
    );
    expect(
      exportFileName(
        'suivi-hebdo',
        'Ã©',
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 11),
        'pdf',
      ),
      'suivi-hebdo-site-2026-10-05-2026-10-11.pdf',
    );
  });
}
