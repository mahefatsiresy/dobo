import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/domain imports no Flutter, Drift or database code', () {
    final offenders = Directory('lib/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) {
          final src = f.readAsStringSync();
          return src.contains('package:flutter') ||
              src.contains('package:drift') ||
              src.contains('package:dobo/db/') ||
              src.contains('../db/');
        })
        .map((f) => f.path);
    expect(offenders, isEmpty);
  });
}
