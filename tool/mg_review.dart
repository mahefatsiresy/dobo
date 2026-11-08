// Round-trips the Malagasy review sheet (docs/mg-review.csv) against
// lib/l10n/app_mg.arb (plan M8 Decision 1):
//
//   dart run tool/mg_review.dart export [csv]   ARB → sheet, keeping ok marks
//   dart run tool/mg_review.dart import [csv]   sheet → ARB, then gen-l10n
//
// The reviewer opens the sheet in a spreadsheet (";" separated, UTF-8),
// corrects the "mg" column and writes "ok" in the last column once a row
// reads right.
import 'dart:convert';
import 'dart:io';

import 'package:dobo/features/exports/csv.dart';

const _header = ['key', 'description', 'fr', 'mg', 'ok'];
const _frArb = 'lib/l10n/app_fr.arb';
const _mgArb = 'lib/l10n/app_mg.arb';
const _sheet = 'docs/mg-review.csv';

bool _isMessage(String key) => !key.startsWith('@');
bool _isOk(String mark) => mark.trim().toLowerCase() == 'ok';

/// The review sheet: a header, then one row per French key in template
/// order. An `ok` mark from [previous] is kept only while the French text
/// it was given for is unchanged.
List<List<String>> reviewRows({
  required Map<String, dynamic> fr,
  required Map<String, dynamic> mg,
  List<List<String>> previous = const [],
}) {
  final before = {
    for (final r in previous.skip(1))
      if (r.length >= 5) r[0]: (fr: r[2], ok: r[4]),
  };
  return [
    _header,
    for (final key in fr.keys.where(_isMessage))
      [
        key,
        switch (fr['@$key']) {
          {'description': final String d} => d,
          _ => '',
        },
        fr[key] as String,
        (mg[key] as String?) ?? '',
        switch (before[key]) {
          (fr: final was, ok: final ok) when was == fr[key] && _isOk(ok) =>
            'ok',
          _ => '',
        },
      ],
  ];
}

/// [mg] with the sheet's non-empty Malagasy cells applied, keys in the
/// template's order ([frKeys]); keys the French no longer has are dropped.
/// `@@` entries are kept, except `@@x-review` once every row is ok.
Map<String, dynamic> applyReview(
  Map<String, dynamic> mg,
  List<List<String>> sheet, {
  required List<String> frKeys,
}) {
  final rows = {
    for (final r in sheet.skip(1))
      if (r.length >= 4 && r[0].isNotEmpty) r[0]: r,
  };
  final allOk =
      frKeys.isNotEmpty &&
      frKeys.every(
        (k) => rows[k] != null && rows[k]!.length >= 5 && _isOk(rows[k]![4]),
      );
  return {
    for (final e in mg.entries)
      if (e.key.startsWith('@@') && !(allOk && e.key == '@@x-review'))
        e.key: e.value,
    for (final k in frKeys)
      // Trimmed only to test for emptiness: a separator like " · " keeps
      // its spaces.
      if (rows[k]?[3] case final text? when text.trim().isNotEmpty)
        k: text
      else if (mg[k] != null)
        k: mg[k],
  };
}

/// An ARB file's text: 2-space indent, trailing newline.
String encodeArb(Map<String, dynamic> arb) =>
    '${const JsonEncoder.withIndent('  ').convert(arb)}\n';

Map<String, dynamic> _readArb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main(List<String> args) {
  if (args.isEmpty || !{'export', 'import'}.contains(args.first)) {
    stderr.writeln('usage: dart run tool/mg_review.dart export|import [csv]');
    exitCode = 64;
    return;
  }
  final sheetFile = File(args.length > 1 ? args[1] : _sheet);
  final fr = _readArb(_frArb);
  final mg = _readArb(_mgArb);
  final previous = sheetFile.existsSync()
      ? decodeCsv(sheetFile.readAsStringSync())
      : const <List<String>>[];
  if (args.first == 'export') {
    final rows = reviewRows(fr: fr, mg: mg, previous: previous);
    sheetFile.writeAsStringSync(encodeCsv(rows));
    final ok = rows.skip(1).where((r) => r[4] == 'ok').length;
    stdout.writeln('wrote ${sheetFile.path}: ${rows.length - 1} rows, $ok ok');
  } else {
    final out = applyReview(
      mg,
      previous,
      frKeys: fr.keys.where(_isMessage).toList(),
    );
    File(_mgArb).writeAsStringSync(encodeArb(out));
    stdout.writeln('wrote $_mgArb; now run: flutter gen-l10n');
  }
}
