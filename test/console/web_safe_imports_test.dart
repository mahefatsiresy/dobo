import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The web console's build must never reach phone-only code (CLAUDE.md
/// §Stack): it would fail to compile for the browser, or fail at run time.
const phoneOnly = [
  'dart:io',
  'dart:ffi',
  'package:drift/',
  'package:drift_flutter/',
  'package:path_provider/',
  'package:image_picker/',
  'package:flutter_image_compress/',
  'package:share_plus/',
  'package:file_picker/',
  'package:printing/',
];

final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// The file a URI from [from] names, or null when it is outside lib/.
String? _resolve(String from, String uri) {
  if (uri.startsWith('package:dobo/')) {
    return 'lib/${uri.substring('package:dobo/'.length)}';
  }
  if (uri.contains(':')) return null;
  return File(from).parent.uri.resolve(uri).toFilePath();
}

/// For each reachable file importing phone-only code, the chain from
/// [entry] to it. A conditional import counts by its default URI only, the
/// one the web build takes.
List<String> phoneOnlyChains(String entry) {
  final root = Directory.current.path;
  String rel(String p) => p.startsWith('$root/') ? p.substring(root.length + 1) : p;
  final seen = <String>{};
  final problems = <String>[];
  void visit(String file, List<String> chain) {
    file = rel(File(file).absolute.path);
    if (!seen.add(file)) return;
    final src = File(file).readAsStringSync();
    for (final m in _directive.allMatches(src)) {
      final uri = m.group(1)!;
      if (phoneOnly.any(uri.startsWith)) {
        problems.add([...chain, file, uri].join(' → '));
        continue;
      }
      final next = _resolve(file, uri);
      if (next != null) visit(next, [...chain, file]);
    }
  }

  visit(entry, const []);
  return problems;
}

void main() {
  test('nothing reachable from main_web.dart imports phone-only code', () {
    expect(phoneOnlyChains('lib/main_web.dart'), isEmpty);
  });

  test('the guard sees phone-only code through the phone app', () {
    expect(phoneOnlyChains('lib/main.dart'), isNotEmpty);
  });
}
