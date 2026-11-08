import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/domain/types.dart';
import 'package:dobo/features/paper/paper_sheet_pdf.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:dobo/l10n/labels.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// Pages in a PDF the `pdf` package wrote (it doesn't compress objects).
int pageCount(Uint8List bytes) =>
    RegExp(r'/Type\s*/Page(?![a-zA-Z])')
        .allMatches(latin1.decode(bytes, allowInvalid: true))
        .length;

void main() {
  final mg = lookupAppLocalizations(const Locale('mg'));
  final fr = lookupAppLocalizations(const Locale('fr'));
  pw.Font font(String name) => pw.Font.ttf(
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync()),
  );
  final regular = font('NotoSans-Regular.ttf');
  final bold = font('NotoSans-Bold.ttf');
  const ponds = [
    PaperPond(code: 'E1', colour: PondColour.blue),
    PaperPond(code: 'E2', colour: PondColour.yellow),
    PaperPond(code: 'E3', colour: PondColour.black),
  ];

  test('three ponds over two weeks make six pages', () async {
    final bytes = await buildPaperSheetPdf(
      ponds: ponds,
      firstWeek: DateTime(2026, 11, 11),
      weeks: 2,
      regular: regular,
      bold: bold,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(pageCount(bytes), 6);
  });

  test('the labels are bilingual', () {
    final labels = paperSheetLabels(mg, fr);
    expect(labels, contains('${mg.deaths} / ${fr.deaths}'));
    expect(labels, contains('${mg.leftovers} / ${fr.leftovers}'));
    expect(labels, contains('${mg.signsSeen} / ${fr.signsSeen}'));
    expect(labels, contains('${mg.waterColourLabel} / ${fr.waterColourLabel}'));
    expect(labels, contains('${mg.paperFeedKg} / ${fr.paperFeedKg}'));
    for (final s in WarningSign.values) {
      expect(labels, contains('${mg.warningSign(s)} / ${fr.warningSign(s)}'));
    }
  });

  test('the week runs Monday to Sunday', () {
    final pages = paperPages(ponds, DateTime(2026, 11, 11), 1);
    expect(pages, hasLength(3));
    expect(pages.first.days.first, DateTime(2026, 11, 9));
    expect(pages.first.days.last, DateTime(2026, 11, 15));
    expect(
      paperWeekLabel(pages.first.days, mg, fr),
      '${mg.paperWeek('09/11/2026', '15/11/2026')} / '
      '${fr.paperWeek('09/11/2026', '15/11/2026')}',
    );
    final twoWeeks = paperPages(
      ponds.take(1).toList(),
      DateTime(2026, 11, 30),
      2,
    );
    expect(twoWeeks.map((p) => p.days.first), [
      DateTime(2026, 11, 30),
      DateTime(2026, 12, 7),
    ]);
  });

  test('several weeks print week by week, ponds in order', () {
    final pages = paperPages(ponds.take(2).toList(), DateTime(2026, 11, 9), 2);
    expect(
      [for (final p in pages) '${p.pond.code} ${p.days.first.day}'],
      ['E1 9', 'E2 9', 'E1 16', 'E2 16'],
    );
  });

  test('no ponds builds one page saying there are no ponds', () async {
    final bytes = await buildPaperSheetPdf(
      ponds: const [],
      firstWeek: DateTime(2026, 11, 9),
      regular: regular,
      bold: bold,
    );
    expect(pageCount(bytes), 1);
  });

  test('paperFileName is fiches-2026-11-09.pdf for any day of that week', () {
    for (var d = 9; d <= 15; d++) {
      expect(paperFileName(DateTime(2026, 11, d)), 'fiches-2026-11-09.pdf');
    }
  });
}
