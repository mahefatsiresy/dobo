// Pure Dart (no Flutter): tool/mg_review.dart uses it too.

/// [rows] as CSV for a French spreadsheet: UTF-8 BOM, `;` between fields,
/// CRLF after each row; a field holding `;`, `"`, CR or LF is quoted with
/// its quotes doubled (plan M8 Decision 9).
String encodeCsv(List<List<String>> rows) {
  String field(String f) =>
      f.contains(RegExp('[;"\r\n]')) ? '"${f.replaceAll('"', '""')}"' : f;
  final out = StringBuffer('﻿');
  for (final row in rows) {
    out
      ..write(row.map(field).join(';'))
      ..write('\r\n');
  }
  return out.toString();
}

/// Rows of a `;` CSV: what [encodeCsv] writes, and what a spreadsheet saves
/// (optional BOM, LF or CRLF, quoted fields over several lines).
List<List<String>> decodeCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var i = text.startsWith('﻿') ? 1 : 0;
  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ';') {
      endField();
    } else if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
      endRow();
      i++;
    } else if (c == '\n') {
      endRow();
    } else {
      field.write(c);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}
