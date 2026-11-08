import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/features/common/pdf_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  Set<int> glyphs(String name) => TtfParser(
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync()),
  ).charToGlyphIndexMap.keys.toSet();

  test('every character the PDFs print has a glyph in a bundled font', () {
    final known = {
      ...glyphs('NotoSans-Regular.ttf'),
      ...glyphs('NotoSansMath-Symbols.ttf'),
    };
    final text = StringBuffer('→×·–≥†');
    for (final arb in ['lib/l10n/app_fr.arb', 'lib/l10n/app_mg.arb']) {
      final map = jsonDecode(File(arb).readAsStringSync()) as Map;
      for (final e in map.entries) {
        if (e.value is String && !(e.key as String).startsWith('@')) {
          text.write(e.value);
        }
      }
    }
    final missing = {
      for (final r in text.toString().runes)
        if (r >= 0x20 && !known.contains(r)) String.fromCharCode(r),
    };
    expect(missing, isEmpty);
  });

  test('bold has the same letters as regular', () {
    final bold = glyphs('NotoSans-Bold.ttf');
    expect(glyphs('NotoSans-Regular.ttf').difference(bold), isEmpty);
  });

  test('the PDF theme falls back on the symbols font', () {
    pw.Font font(String name) => pw.Font.ttf(
      ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync()),
    );
    final symbols = font('NotoSansMath-Symbols.ttf');
    final theme = pdfTheme(
      regular: font('NotoSans-Regular.ttf'),
      bold: font('NotoSans-Bold.ttf'),
      symbols: symbols,
    );
    expect(theme.defaultTextStyle.fontFallback, contains(symbols));
  });
}
