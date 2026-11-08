import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/pictogram_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  final all = [
    for (final s in WarningSign.values) (s.name, warningSignPath(s)),
    for (final l in Leftover.values) (l.name, leftoverPath(l)),
  ];

  test('every sign and leftover has a path', () {
    for (final (name, path) in all) {
      expect(path, startsWith('M'), reason: name);
    }
  });

  test('the outlines fit the 24 box', () {
    final number = RegExp(r'-?\d+(\.\d+)?');
    for (final (name, path) in all) {
      for (final m in number.allMatches(path)) {
        final v = double.parse(m.group(0)!);
        expect(v, inInclusiveRange(-1, 25), reason: '$name: $v');
      }
    }
  });

  test('pictogramSvg builds a pdf image', () async {
    final doc = pw.Document()
      ..addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6,
          build: (_) => pw.SizedBox(
            width: 48,
            height: 48,
            child: pw.SvgImage(
              svg: pictogramSvg(warningSignPath(WarningSign.whiteSpots)),
            ),
          ),
        ),
      );
    final bytes = await doc.save();
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
