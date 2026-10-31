import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release builds may use the network to sync', () {
    // Flutter adds INTERNET only to debug and profile builds.
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android.permission.INTERNET'));
  });
}
