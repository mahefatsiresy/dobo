// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:dobo/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // v2 only adds tables; this pins that the site and the device id survive.
  test('migration from v1 to v2 keeps the site and device id', () async {
    const siteId = '0190d5a0-0000-7000-8000-000000000001';
    const at = '2026-03-01T09:00:00.000Z';
    final oldSitesData = <v1.SitesData>[
      const v1.SitesData(
        id: siteId,
        associationId: 'a1',
        enteredBy: 'u1',
        createdAtDevice: at,
        deviceId: 'd1',
        syncState: 'pending',
        updatedAtDevice: at,
        name: 'Ambohidratrimo',
      ),
    ];
    final expectedNewSitesData = <v2.SitesData>[
      const v2.SitesData(
        id: siteId,
        associationId: 'a1',
        enteredBy: 'u1',
        createdAtDevice: at,
        deviceId: 'd1',
        syncState: 'pending',
        updatedAtDevice: at,
        name: 'Ambohidratrimo',
      ),
    ];

    final oldLocalMetaData = <v1.LocalMetaData>[
      const v1.LocalMetaData(key: 'device_id', value: 'd1'),
    ];
    final expectedNewLocalMetaData = <v2.LocalMetaData>[
      const v2.LocalMetaData(key: 'device_id', value: 'd1'),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.sites, oldSitesData);
        batch.insertAll(oldDb.localMeta, oldLocalMetaData);
      },
      validateItems: (newDb) async {
        expect(expectedNewSitesData, await newDb.select(newDb.sites).get());
        expect(
          expectedNewLocalMetaData,
          await newDb.select(newDb.localMeta).get(),
        );
      },
    );
  });
}
