import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;
  final fr = arb('fr');
  final mg = arb('mg');
  final keys = [for (final k in fr.keys) if (!k.startsWith('@')) k];

  test('every French key has a Malagasy text', () {
    final missing = [
      for (final k in keys)
        if (mg[k] is! String || (mg[k] as String).trim().isEmpty) k,
    ];
    expect(missing, isEmpty, reason: '${missing.length} keys without Malagasy');
  });

  test('no Malagasy text drops a placeholder', () {
    final dropped = <String>[];
    for (final k in keys) {
      final text = mg[k];
      if (text is! String) continue;
      final meta = fr['@$k'];
      final names = meta is Map && meta['placeholders'] is Map
          ? (meta['placeholders'] as Map).keys.cast<String>()
          : const <String>[];
      bool uses(String s, String name) =>
          s.contains('{$name}') || s.contains('{$name,');
      for (final name in names) {
        if (uses(fr[k] as String, name) && !uses(text, name)) {
          dropped.add('$k: {$name}');
        }
      }
    }
    expect(dropped, isEmpty);
  });

  test('the mg file has no key the French lacks', () {
    final extra = [
      for (final k in mg.keys)
        if (!k.startsWith('@') && !fr.containsKey(k)) k,
    ];
    expect(extra, isEmpty);
  });
}
