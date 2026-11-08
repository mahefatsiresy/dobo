import 'package:dobo/features/exports/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a field with ; " CR or LF is quoted with doubled quotes', () {
    final text = encodeCsv([
      ['plain', 'a;b', 'say "hi"', 'two\nlines', 'cr\rhere'],
    ]);
    expect(text, '﻿plain;"a;b";"say ""hi""";"two\nlines";"cr\rhere"\r\n');
  });

  test('the file starts with a BOM and ends lines with CRLF', () {
    final text = encodeCsv([
      ['a', 'b'],
      ['1', '2'],
    ]);
    expect(text, '﻿a;b\r\n1;2\r\n');
  });

  test('decodeCsv reads back encodeCsv', () {
    final rows = [
      ['clé', 'étang;E1', 'il a dit "non"', 'ligne 1\nligne 2', ''],
      ['', 'Rien', '', '', 'fin'],
    ];
    expect(decodeCsv(encodeCsv(rows)), rows);
  });

  test('decodeCsv reads LF files without a BOM', () {
    expect(decodeCsv('a;b\n"x\ny";\n'), [
      ['a', 'b'],
      ['x\ny', ''],
    ]);
  });

  test('decodeCsv keeps a last line with no line end', () {
    expect(decodeCsv('a;b\r\nc;d'), [
      ['a', 'b'],
      ['c', 'd'],
    ]);
  });
}
