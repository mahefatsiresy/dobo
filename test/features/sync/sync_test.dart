import 'package:dobo/db/database.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/ids.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/providers.dart';
import 'package:dobo/db/repositories/photo_repository.dart';
import 'package:dobo/db/photo_files.dart';

import 'dart:io';

import 'package:dobo/sync/sync_controller.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../../sync/fake_auth_gateway.dart';
import '../../sync/fake_sync_api.dart';
import '../../sync/fake_photo_store.dart';
import '../photos/photo_strip_test.dart' show tinyImage;

/// A phone linked to an account, with a server that answers.
Future<void> link(AppDatabase db) => db
    .into(db.localMeta)
    .insert(LocalMetaCompanion.insert(key: 'linked', value: '1'));

Future<void> addLogs(
  WidgetTester tester,
  AppDatabase db,
  List<String> ids,
) async {
  final s = (await appContainer(tester).read(sessionProvider.future))!;
  for (final id in ids) {
    await db
        .into(db.dailyLogs)
        .insert(
          DailyLogsCompanion.insert(
            id: Value(id),
            associationId: s.associationId,
            enteredBy: s.userId,
            deviceId: s.deviceId,
            recordedAt: DateTime.utc(2026, 3, 1, 9),
            pondId: 'p1',
            feedGivenG: 600,
          ),
        );
  }
  await tester.pumpAndSettle();
}

void main() {
  late FakeSyncApi server;

  setUp(() => server = FakeSyncApi());

  // Read lazily: tests are declared before setUp makes the server.
  List<Override> online() => [
    syncApiProvider.overrideWith((ref) => server),
    authGatewayProvider.overrideWith(
      (ref) => FakeAuthGateway()..signedIn = true,
    ),
  ];

  appTest('Synchroniser sends what is pending and clears the badge', (
    tester,
    db,
  ) async {
    await link(db);
    await tester.pumpAndSettle();
    await addLogs(tester, db, ['l1', 'l2']);
    expect(
      find.descendant(
        of: find.byKey(const Key('syncBadge')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Synchronisation'));
    await tapAndSettle(tester, find.text('Synchroniser'));

    expect(server.rows['daily_logs'], hasLength(2));
    expect(find.text('2'), findsNothing);
  }, overrides: online());

  appTest('a refused row is listed with the reason and can be retried', (
    tester,
    db,
  ) async {
    await link(db);
    await tester.pumpAndSettle();
    server.refuse('daily_logs', '42501');
    await addLogs(tester, db, ['l1']);
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Synchronisation'));
    await tapAndSettle(tester, find.text('Synchroniser'));

    expect(
      find.text('Votre rôle ne permet pas cet enregistrement'),
      findsOneWidget,
    );
    // Once the server accepts it (say, a member signs in), retrying sends it.
    server.accept('daily_logs');
    await tapAndSettle(tester, find.text('Réessayer les refusés'));
    final log = await db.select(db.dailyLogs).getSingle();
    expect(log.syncState, SyncState.synced);
    expect(
      find.text('Votre rôle ne permet pas cet enregistrement'),
      findsNothing,
    );
  }, overrides: online());

  appTest('an M3 phone is offered to create the association\'s account', (
    tester,
    db,
  ) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Synchronisation'));
    expect(find.text('Créer le compte de l\'association'), findsOneWidget);
  }, overrides: online());

  test('two syncs asked for at once run once', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await SetupRepository(db).completeSetup(siteName: 'Ambohidratrimo');
    await link(db);
    final c = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db), ...online()],
    );
    addTearDown(c.dispose);
    // Riverpod pauses providers nobody listens to.
    c.listen(sessionProvider, (_, _) {});
    await c.read(sessionProvider.future);
    final sync = c.read(syncControllerProvider.notifier);
    final first = sync.syncNow();
    final second = sync.syncNow();
    expect(identical(first, second), true);
    await Future.wait([first, second]);
    // One run: the site pushed, then one pull per synced table.
    expect(server.calls, 1 + 18);
    expect(c.read(syncControllerProvider).state, SyncRunState.idle);
  });

  for (final admin in [true, false]) {
    test('sync on ${admin ? 'an admin' : 'a member'} session '
        '${admin ? 'links' : "doesn't link"} accounts to people', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final s = await SetupRepository(db)
          .completeSetup(siteName: 'Ambohidratrimo', isAdmin: admin);
      await link(db);
      await db
          .into(db.members)
          .insert(
            MembersCompanion.insert(
              id: const Value('m2'),
              associationId: s.associationId,
              enteredBy: s.userId,
              deviceId: 'other',
              name: 'Hery',
              role: MemberRole.member,
              locale: 'fr',
              syncState: const Value(SyncState.synced),
            ),
          );
      final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db), ...online()],
      );
      addTearDown(c.dispose);
      c.listen(sessionProvider, (_, _) {});
      await c.read(sessionProvider.future);
      await c.read(syncControllerProvider.notifier).syncNow();
      final m = await (db.select(
        db.members,
      )..where((m) => m.id.equals('m2'))).getSingle();
      expect(m.personId, admin ? accountPersonId('m2') : isNull);
    });
  }

  /// A photo row of this phone, marked to send.
  Future<void> markedPhoto(AppDatabase db, String key) async {
    final s = (await SetupRepository(db).currentSession())!;
    await db
        .into(db.photos)
        .insert(
          PhotosCompanion.insert(
            id: Value(key),
            associationId: s.associationId,
            enteredBy: s.userId,
            deviceId: s.deviceId,
            recordedAt: DateTime.utc(2026, 3, 20),
            ownerKind: PhotoOwner.visit,
            ownerId: 'v1',
            photoKey: key,
            upload: const Value(true),
            bytes: 100,
          ),
        );
  }

  appTest('the sync screen lists photos waiting, and the cap', (
    tester,
    db,
  ) async {
    await markedPhoto(db, 'k1');
    await markedPhoto(db, 'k2');
    await db
        .into(db.photoUploads)
        .insert(
          PhotoUploadsCompanion.insert(
            photoKey: 'k2',
            error: const Value('cap'),
          ),
        );
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Synchronisation'));
    expect(find.text("Photos en attente d'envoi : 2"), findsOneWidget);
    expect(
      find.text(
        'Limite de photos atteinte : un administrateur peut la relever '
        'dans Réglages.',
      ),
      findsOneWidget,
    );
  });

  test('a sync sends the photos marked to send', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final s = await SetupRepository(db).completeSetup(siteName: 'A');
    await link(db);
    final docs = Directory.systemTemp.createTempSync('dobo-docs');
    final files = PhotoFiles(
      docs: () async => docs,
      cache: () async => Directory.systemTemp.createTempSync('dobo-cache'),
    );
    final key = await PhotoRepository(
      db,
      s,
      files,
    ).add(owner: PhotoOwner.visit, ownerId: 'v1', jpeg: tinyImage);
    await PhotoRepository(db, s, files).setUpload(key, true);
    final store = FakePhotoStore();
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        ...online(),
        photoStoreProvider.overrideWithValue(store),
        photoFilesProvider.overrideWithValue(files),
      ],
    );
    addTearDown(c.dispose);
    c.listen(sessionProvider, (_, _) {});
    await c.read(sessionProvider.future);
    await c.read(syncControllerProvider.notifier).syncNow();
    expect(store.objects.keys, ['${s.associationId}/$key.jpg']);
  });
}
