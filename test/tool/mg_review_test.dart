import 'package:dobo/features/exports/csv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/mg_review.dart';

void main() {
  final fr = <String, dynamic>{
    '@@locale': 'fr',
    'save': 'Enregistrer',
    '@save': {'description': 'Bouton'},
    'pond': 'Étang',
    'fish': '{count} poissons',
    '@fish': {
      'placeholders': {
        'count': {'type': 'String'},
      },
    },
  };
  final mg = <String, dynamic>{
    '@@locale': 'mg',
    '@@x-review': 'drafts',
    'save': 'Tehirizina',
    'pond': 'Dobo',
    'fish': 'trondro {count}',
  };

  test('export lists every key with its description and the review mark', () {
    final rows = reviewRows(fr: fr, mg: mg);
    expect(rows.first, ['key', 'description', 'fr', 'mg', 'ok']);
    expect(rows.skip(1).toList(), [
      ['save', 'Bouton', 'Enregistrer', 'Tehirizina', ''],
      ['pond', '', 'Étang', 'Dobo', ''],
      ['fish', '', '{count} poissons', 'trondro {count}', ''],
    ]);
  });

  test('export keeps ok marks whose French is unchanged and clears the '
      'others', () {
    final previous = [
      ['key', 'description', 'fr', 'mg', 'ok'],
      ['save', 'Bouton', 'Enregistrer', 'Tehirizina', 'ok'],
      ['pond', '', 'Bassin', 'Dobo', 'ok'],
    ];
    final rows = reviewRows(fr: fr, mg: mg, previous: previous);
    expect(rows[1].last, 'ok');
    expect(rows[2].last, '');
  });

  test('import sets the corrected Malagasy and leaves the rest', () {
    final sheet = [
      ['key', 'description', 'fr', 'mg', 'ok'],
      ['save', '', 'Enregistrer', 'Tahiry', 'ok'],
      ['pond', '', 'Étang', '', ''],
      ['gone', '', 'Ancien', 'Taloha', 'ok'],
    ];
    final out = applyReview(mg, sheet, frKeys: ['save', 'pond', 'fish']);
    expect(out['save'], 'Tahiry');
    expect(out['pond'], 'Dobo');
    expect(out.containsKey('gone'), isFalse);
    expect(out['@@locale'], 'mg');
    expect(out['@@x-review'], 'drafts');
    expect(out.keys.toList(), [
      '@@locale',
      '@@x-review',
      'save',
      'pond',
      'fish',
    ]);
  });

  test('import drops @@x-review only when every row is ok', () {
    final sheet = [
      ['key', 'description', 'fr', 'mg', 'ok'],
      ['save', '', 'Enregistrer', 'Tehirizina', 'ok'],
      ['pond', '', 'Étang', 'Dobo', 'OK'],
      ['fish', '', '{count} poissons', 'trondro {count}', 'ok '],
    ];
    final out = applyReview(mg, sheet, frKeys: ['save', 'pond', 'fish']);
    expect(out.containsKey('@@x-review'), isFalse);
  });

  test('a CSV saved by LibreOffice (LF, no BOM) imports', () {
    final sheet = decodeCsv(
      'key;description;fr;mg;ok\nsave;;Enregistrer;"Tahiry; vita";ok\n',
    );
    final out = applyReview(mg, sheet, frKeys: ['save', 'pond', 'fish']);
    expect(out['save'], 'Tahiry; vita');
  });

  test('the ARB is written with 2-space indent and a trailing newline', () {
    expect(
      encodeArb({'@@locale': 'mg', 'a': 'b'}),
      '{\n  "@@locale": "mg",\n  "a": "b"\n}\n',
    );
  });

  test("import keeps a cell's leading and trailing spaces", () {
    final sheet = [
      ['key', 'description', 'fr', 'mg', 'ok'],
      ['save', '', 'Enregistrer', ' · ', ''],
    ];
    final out = applyReview(mg, sheet, frKeys: ['save']);
    expect(out['save'], ' · ');
  });
}
