// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:dobo/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;

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

  // v3 only adds tables; a pond and its stocking survive unchanged.
  test('migration from v2 to v3 keeps ponds and stockings', () async {
    const at = '2026-03-01T09:00:00.000Z';
    const pondId = '0190d5a0-0000-7000-8000-000000000002';
    const stockingId = '0190d5a0-0000-7000-8000-000000000003';

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.ponds,
          const v2.PondsData(
            id: pondId,
            associationId: 'a1',
            enteredBy: 'u1',
            createdAtDevice: at,
            deviceId: 'd1',
            syncState: 'pending',
            updatedAtDevice: at,
            siteId: 's1',
            code: 'E1',
            colour: 'blue',
            structure: 'earth',
            role: 'growout',
            lengthM: 25,
            status: 'stocked',
            archived: 0,
          ),
        );
        batch.insert(
          oldDb.stockings,
          const v2.StockingsData(
            id: stockingId,
            associationId: 'a1',
            enteredBy: 'u1',
            createdAtDevice: at,
            deviceId: 'd1',
            syncState: 'pending',
            recordedAt: at,
            isTombstone: 0,
            batchId: 'b1',
            pondId: pondId,
            count: 1000,
            avgWeightMg: 12500,
          ),
        );
      },
      validateItems: (newDb) async {
        final pond = await newDb.select(newDb.ponds).getSingle();
        expect((pond.id, pond.code, pond.lengthM, pond.status),
            (pondId, 'E1', 25.0, 'stocked'));
        final stocking = await newDb.select(newDb.stockings).getSingle();
        expect((stocking.id, stocking.count, stocking.avgWeightMg),
            (stockingId, 1000, 12500));
        expect(await newDb.select(newDb.dailyLogs).get(), isEmpty);
      },
    );
  });

  // v4 only adds groups, members and setting overrides; a pond and a daily
  // log survive unchanged.
  test('migration from v3 to v4 keeps ponds and daily logs', () async {
    const at = '2026-03-01T09:00:00.000Z';
    const pondId = '0190d5a0-0000-7000-8000-000000000004';
    const logId = '0190d5a0-0000-7000-8000-000000000005';

    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.ponds,
          const v3.PondsData(
            id: pondId,
            associationId: 'a1',
            enteredBy: 'u1',
            createdAtDevice: at,
            deviceId: 'd1',
            syncState: 'pending',
            updatedAtDevice: at,
            siteId: 's1',
            code: 'E1',
            colour: 'blue',
            structure: 'earth',
            role: 'growout',
            status: 'stocked',
            archived: 0,
          ),
        );
        batch.insert(
          oldDb.dailyLogs,
          const v3.DailyLogsData(
            id: logId,
            associationId: 'a1',
            enteredBy: 'u1',
            createdAtDevice: at,
            deviceId: 'd1',
            syncState: 'pending',
            recordedAt: at,
            isTombstone: 0,
            pondId: pondId,
            feedGivenG: 600,
            ateFast: 0,
            deaths: 3,
            deathSigns: '',
            warningSigns: 'rubbing',
          ),
        );
      },
      validateItems: (newDb) async {
        final pond = await newDb.select(newDb.ponds).getSingle();
        expect((pond.id, pond.code, pond.status), (pondId, 'E1', 'stocked'));
        final log = await newDb.select(newDb.dailyLogs).getSingle();
        expect((log.id, log.feedGivenG, log.deaths, log.warningSigns),
            (logId, 600, 3, 'rubbing'));
        expect(await newDb.select(newDb.members).get(), isEmpty);
      },
    );
  });
}
