import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colour means which pond or how urgent (docs/design.md): features take
/// colours from the theme, never a raw Material hue. Pond tags and the PDFs
/// keep their own fixed colours.
void main() {
  test('features name no raw Colors hue', () {
    final hue = RegExp(
      r'Colors\.(red|amber|green|orange|blue|purple|teal|grey|yellow|brown|'
      r'pink|indigo|cyan|lime|deepOrange|deepPurple|lightBlue|lightGreen|'
      r'blueGrey)\b',
    );
    final exempt = {'pond_colour.dart', 'pdf_theme.dart'};
    final found = <String>[];
    for (final f in Directory('lib/features').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final name = f.uri.pathSegments.last;
      if (exempt.contains(name) || name.endsWith('_pdf.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (hue.hasMatch(lines[i])) found.add('${f.path}:${i + 1}');
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
