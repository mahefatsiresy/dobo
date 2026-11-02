@Tags(['server'])
library;

import 'package:dobo/db/database.dart';
import 'package:dobo/sync/photo_uploader.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/db/repositories/report_repository.dart';
import 'package:dobo/db/repositories/photo_repository.dart';
import 'package:dobo/db/repositories/person_repository.dart';
import 'package:dobo/db/photo_files.dart';
import 'package:dobo/db/ids.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/facts_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/alerts/farm_alerts.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:dobo/sync/photo_store.dart';
import 'package:dobo/sync/supabase_auth_gateway.dart';
import 'package:dobo/sync/supabase_photo_store.dart';
import 'package:dobo/sync/supabase_sync_api.dart';
import 'package:dobo/sync/sync_api.dart';
import 'package:dobo/sync/sync_engine.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import 'dart:io';

import 'server_env.dart';

/// Two phones on the real local server: the founder (admin) and a worker.
void main() {
  late ServerEnv env;
  late AppDatabase founderPhone;
  late AppDatabase workerPhone;
  late SyncEngine founderSync;
  late SyncEngine workerSync;
  late String associationId;
  late String founderId;
  late String workerId;
  late SupabaseClient founderClient;
  late SupabaseClient workerClient;
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final founderDevice = newId();
  final workerDevice = newId();
  final siteId = newId();
  final pondId = newId();

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    env = ServerEnv.fromEnvironment();
    associationId = newId();
    founderId = newId();
    workerId = newId();

    founderClient = env.anonClient();
    final founder = SupabaseAuthGateway(founderClient);
    await founder.signUp(email: 'f$stamp@test.mg', password: 'motdepasse1');
    await founder.createAssociation(
      associationId: associationId,
      associationName: 'Famille $stamp',
      groupId: newId(),
      groupName: 'Branche 1',
      memberId: founderId,
      memberName: 'Founder',
      locale: 'fr',
      deviceId: founderDevice,
    );
    await founder.createAccount(
      NewAccount(
        memberId: workerId,
        name: 'Rakoto',
        role: MemberRole.worker,
        login: 'r$stamp',
        secret: '123456',
        locale: 'mg',
        deviceId: founderDevice,
      ),
    );
    final me = await founder.myMember();
    expect(
      (me.id, me.isAdmin, me.associationName),
      (founderId, true, 'Famille $stamp'),
    );

    workerClient = env.anonClient();
    final worker = SupabaseAuthGateway(workerClient);
    await worker.signIn(email: workerEmail('r$stamp'), password: '123456');
    final w = await worker.myMember();
    expect((w.id, w.role), (workerId, MemberRole.worker));

    founderPhone = AppDatabase(NativeDatabase.memory());
    workerPhone = AppDatabase(NativeDatabase.memory());
    founderSync = SyncEngine(founderPhone, SupabaseSyncApi(founderClient));
    workerSync = SyncEngine(workerPhone, SupabaseSyncApi(workerClient));
  });

  tearDownAll(() async {
    await founderPhone.close();
    await workerPhone.close();
  });

  Future<void> logs(AppDatabase phone, String by, String device, int n) =>
      phone.batch((b) {
        for (var i = 0; i < n; i++) {
          b.insert(
            phone.dailyLogs,
            DailyLogsCompanion.insert(
              associationId: associationId,
              enteredBy: by,
              deviceId: device,
              recordedAt: DateTime.utc(2026, 3, 1, 9),
              pondId: pondId,
              feedGivenG: 600,
            ),
          );
        }
      });

  test('the founder adds a pond, the worker logs it, the founder sees the '
      'log', () async {
    await founderPhone
        .into(founderPhone.sites)
        .insert(
          SitesCompanion.insert(
            id: Value(siteId),
            associationId: associationId,
            enteredBy: founderId,
            deviceId: founderDevice,
            name: 'Ambohidratrimo',
          ),
        );
    await founderPhone
        .into(founderPhone.ponds)
        .insert(
          PondsCompanion.insert(
            id: Value(pondId),
            associationId: associationId,
            enteredBy: founderId,
            deviceId: founderDevice,
            siteId: siteId,
            code: 'E1',
            colour: PondColour.blue,
            role: PondRole.growout,
          ),
        );
    final pushed = await founderSync.run();
    expect((pushed.pushed, pushed.rejected), (2, 0));

    await workerSync.run();
    final pond = await workerPhone.select(workerPhone.ponds).getSingle();
    expect((pond.code, pond.syncState), ('E1', SyncState.synced));
    expect(
      (await workerPhone.select(workerPhone.members).get()).map((m) => m.name),
      containsAll(['Founder', 'Rakoto']),
    );

    await logs(workerPhone, workerId, workerDevice, 1);
    await workerSync.run();
    await founderSync.run();
    final log = await founderPhone.select(founderPhone.dailyLogs).getSingle();
    expect((log.enteredBy, log.syncState), (workerId, SyncState.synced));
  });

  test('a worker\'s water reading is refused and kept', () async {
    await workerPhone
        .into(workerPhone.waterReadings)
        .insert(
          WaterReadingsCompanion.insert(
            associationId: associationId,
            enteredBy: workerId,
            deviceId: workerDevice,
            recordedAt: DateTime.utc(2026, 3, 1, 9),
            pondId: pondId,
            ph: const Value(7.2),
          ),
        );
    final report = await workerSync.run();
    expect(report.rejected, 1);
    final r = await workerPhone.select(workerPhone.waterReadings).getSingle();
    expect(r.syncState, SyncState.rejected);
    expect(r.syncError, startsWith('42501'));
  });

  test('Review Focus 3: two phones pushing at once, each then has every '
      'row', () async {
    await logs(founderPhone, founderId, founderDevice, 100);
    await logs(workerPhone, workerId, workerDevice, 100);
    await Future.wait([founderSync.run(), workerSync.run()]);
    await Future.wait([founderSync.run(), workerSync.run()]);

    for (final phone in [founderPhone, workerPhone]) {
      final all = await phone.select(phone.dailyLogs).get();
      expect(all, hasLength(201));
      expect(all.every((l) => l.syncState == SyncState.synced), true);
    }
  });

  test('a client nobody is signed in on is told so, not refused row by '
      'row', () async {
    final api = SupabaseSyncApi(env.anonClient());
    await expectLater(
      api.push('daily_logs', const []),
      throwsA(isA<SyncSignedOut>()),
    );
  });

  test(
    'M5: a pond-day logged on both phones is flagged on both, and '
    'keeping one on the founder\'s phone clears it on the worker\'s',
    () async {
      final day = DateTime(2026, 3, 5);
      Session session(String user, String device, MemberRole role) => Session(
        associationId: associationId,
        userId: user,
        deviceId: device,
        siteId: siteId,
        role: role,
        isLinked: true,
      );
      final founderLogs = DailyLogRepository(
        founderPhone,
        session(founderId, founderDevice, MemberRole.member),
      );
      final workerLogs = DailyLogRepository(
        workerPhone,
        session(workerId, workerDevice, MemberRole.worker),
      );
      // Both offline: each phone logs E1 on 05/03.
      final kept = await founderLogs.save(
        DailyLogInput(pondId: pondId, date: day, feedGivenG: 4000),
      );
      await workerLogs.save(
        DailyLogInput(pondId: pondId, date: day, feedGivenG: 4200),
      );
      await workerSync.run();
      await founderSync.run();
      await workerSync.run();

      Future<List<String>> flagged(AppDatabase phone) async => [
        for (final a in duplicateLogAlerts((await currentFacts(phone)).logs))
          if (a.facts['date'] == day) ...(a.facts['logIds']! as List<String>),
      ];
      expect(await flagged(founderPhone), hasLength(2));
      expect(await flagged(workerPhone), hasLength(2));

      final theirs = (await flagged(founderPhone))
          .singleWhere((id) => id != kept);
      final copy = await founderLogs.keepOnly(kept, [theirs]);
      final pushed = await founderSync.run();
      expect(pushed.rejected, 0);
      await workerSync.run();
      expect(await flagged(founderPhone), isEmpty);
      expect(await flagged(workerPhone), isEmpty);
      final left = (await workerLogs.forDay(pondId, day))!;
      expect((left.id, left.supersedesId, left.feedGivenG), (copy, kept, 4000));
    },
  );

  test('M6: a photo the founder sends downloads on the worker\'s phone; '
      'sending it again counts as done; past the cap it waits', () async {
    final founderStore = SupabasePhotoStore(founderClient);
    final workerStore = SupabasePhotoStore(workerClient);
    final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 7, 7, 7]);
    final path = photoPath(associationId, newId());

    await founderStore.upload(path, bytes);
    expect(await workerStore.download(path), bytes);
    await expectLater(
      founderStore.upload(path, bytes),
      throwsA(isA<PhotoAlreadyStored>()),
    );
    expect(
      await workerStore.download(photoPath(associationId, newId())),
      isNull,
    );

    // The admin caps the association at the one photo it has.
    final out = await Process.run('psql', [
      env.dbUrl,
      '-c',
      "insert into setting_overrides (id, association_id, entered_by, "
          "created_at_device, device_id, updated_at_device, site_id, key, "
          "value) values ('${newId()}', '$associationId', '$founderId', "
          "now(), '$founderDevice', now(), '$siteId', 'photoUploadCap', 1)",
    ]);
    expect(out.exitCode, 0, reason: '${out.stderr}');
    await expectLater(
      founderStore.upload(photoPath(associationId, newId()), bytes),
      throwsA(isA<PhotoCapReached>()),
    );
  });

  test('M6: a report published offline on the founder\'s phone reaches a '
      'member\'s phone unread, with its numbers and its photo; an admin '
      'sync gives every account one person', () async {
    // The test before capped this association at one photo: lift it.
    final lift = await Process.run('psql', [
      env.dbUrl,
      '-c',
      "delete from setting_overrides where association_id = '$associationId' "
          "and key = 'photoUploadCap'",
    ]);
    expect(lift.exitCode, 0, reason: '${lift.stderr}');

    // A second member, with a phone of their own.
    final heryId = newId();
    final heryDevice = newId();
    await SupabaseAuthGateway(founderClient).createAccount(
      NewAccount(
        memberId: heryId,
        name: 'Hery',
        role: MemberRole.member,
        login: 'h$stamp@test.mg',
        secret: 'motdepasse2',
        locale: 'fr',
        deviceId: founderDevice,
      ),
    );
    final heryClient = await env.signedInClient(
      'h$stamp@test.mg',
      'motdepasse2',
    );
    final heryPhone = AppDatabase(NativeDatabase.memory());
    addTearDown(heryPhone.close);
    final herySync = SyncEngine(heryPhone, SupabaseSyncApi(heryClient));
    final founder = Session(
      associationId: associationId,
      userId: founderId,
      deviceId: founderDevice,
      siteId: siteId,
      isAdmin: true,
      isLinked: true,
    );
    final hery = Session(
      associationId: associationId,
      userId: heryId,
      deviceId: heryDevice,
      siteId: siteId,
      isLinked: true,
    );
    PhotoFiles tempFiles() {
      final docs = Directory.systemTemp.createTempSync('dobo-docs');
      final cache = Directory.systemTemp.createTempSync('dobo-cache');
      return PhotoFiles(docs: () async => docs, cache: () async => cache);
    }

    // Offline on the founder's phone: a photo marked to send, a report.
    final founderFiles = tempFiles();
    final photos = PhotoRepository(founderPhone, founder, founderFiles);
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 9, 9, 9]);
    final visitId = newId();
    final key = await photos.add(
      owner: PhotoOwner.visit,
      ownerId: visitId,
      jpeg: jpeg,
    );
    await photos.setUpload(key, true);
    final day = farmDateToUtc(DateTime(2026, 3, 20));
    final reportId = await ReportRepository(founderPhone, founder).publish(
      visitId: visitId,
      content: ReportContent(
        header: ReportHeader(
          siteName: 'Ambohidratrimo',
          visitDay: day,
          memberName: 'Founder',
          periodFrom: farmDateToUtc(DateTime(2026, 3, 13)),
          periodTo: day,
          builtAt: day,
        ),
        health: const [PondHealth(pondId: 'e1', deaths: 6)],
        visitPhotoKeys: [key],
      ),
    );

    // Back online: rows, then the photo; the admin phone links accounts.
    await founderSync.run();
    final founderStore = SupabasePhotoStore(founderClient);
    expect(
      await PhotoUploader(
        founderPhone,
        founderStore,
        founderFiles,
        founder,
      ).run(),
      1,
    );
    expect(
      await PersonRepository(founderPhone, founder).ensureAccountPeople(),
      greaterThanOrEqualTo(3),
    );
    await founderSync.run();

    // The member's phone.
    await herySync.run();
    final unread = await ReportRepository(
      heryPhone,
      hery,
    ).watchUnreadIds().first;
    expect(unread, {reportId});
    final row = await (heryPhone.select(
      heryPhone.visitReports,
    )..where((r) => r.id.equals(reportId))).getSingle();
    final content = ReportContent.decode(row.content);
    expect(content.health.single.deaths, 6);
    final file = await tempFiles().fetch(
      content.visitPhotoKeys.single,
      associationId: associationId,
      store: SupabasePhotoStore(heryClient),
    );
    expect(file!.readAsBytesSync(), jpeg);

    // One person per account, the same on both phones.
    final members = await heryPhone.select(heryPhone.members).get();
    final people = await heryPhone.select(heryPhone.people).get();
    for (final m in members) {
      expect(m.personId, isNotNull, reason: m.name);
      expect(people.where((p) => p.id == m.personId), hasLength(1));
    }
  });
}
