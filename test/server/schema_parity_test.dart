@Tags(['server'])
library;

import 'dart:io';

import 'package:dobo/db/database.dart';
import 'package:dobo/sync/row_codec.dart';
import 'package:dobo/sync/sync_tables.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'server_env.dart';

/// Postgres types each Drift type may map to.
const _families = {
  DriftSqlType.string: {'text', 'uuid'},
  DriftSqlType.int: {'integer', 'bigint'},
  DriftSqlType.bigInt: {'bigint'},
  DriftSqlType.double: {'double precision'},
  DriftSqlType.bool: {'boolean'},
  DriftSqlType.dateTime: {'timestamp with time zone'},
};

void main() {
  test('every synced Drift column exists on the server with a matching '
      'type', () async {
    final env = ServerEnv.fromEnvironment();
    final out = await Process.run('psql', [
      env.dbUrl,
      '-At',
      '-c',
      "select table_name || '.' || column_name || '=' || data_type "
          "from information_schema.columns where table_schema = 'public'",
    ]);
    expect(out.exitCode, 0, reason: '${out.stderr}');
    final server = {
      for (final line in (out.stdout as String).trim().split('\n'))
        line.split('=').first: line.split('=').last,
    };

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final problems = <String>[];
    for (final t in syncTables(db)) {
      for (final c in t.info.$columns) {
        if (localOnlyColumns.contains(c.$name)) continue;
        final key = '${t.name}.${c.$name}';
        final type = server[key];
        if (type == null) {
          problems.add('$key missing');
        } else if (!_families[c.type]!.contains(type)) {
          problems.add('$key is $type, phone has ${c.type}');
        }
      }
    }
    expect(problems, isEmpty);
  });
}
