import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/db/database.dart';
import 'package:dobo/db/photo_files.dart';
import 'package:dobo/db/repositories/photo_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/photo_uploader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/repo_fixtures.dart';
import 'fake_photo_store.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late Directory docs, cache;
  late PhotoFiles files;
  late PhotoRepository photos;
  late FakePhotoStore store;
  late PhotoUploader uploader;
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 3]);

  setUp(() async {
    (db, session) = await setUpFarm();
    docs = Directory.systemTemp.createTempSync('dobo-docs');
    cache = Directory.systemTemp.createTempSync('dobo-cache');
    files = PhotoFiles(docs: () async => docs, cache: () async => cache);
    photos = PhotoRepository(db, session, files);
    store = FakePhotoStore();
    uploader = PhotoUploader(db, store, files, session);
  });
  tearDown(() async {
    await db.close();
    docs.deleteSync(recursive: true);
    cache.deleteSync(recursive: true);
  });

  Future<String> photo({bool upload = true}) async {
    final key = await photos.add(
      owner: PhotoOwner.visit,
      ownerId: 'v1',
      jpeg: jpeg,
    );
    if (upload) await photos.setUpload(key, true);
    return key;
  }

  String path(String key) => '${session.associationId}/$key.jpg';

  test('uploads only marked photos whose file is here, once', () async {
    final sent = await photo();
    await photo(upload: false);
    final gone = await photo();
    (await files.ownFile(gone)).deleteSync();

    expect(await uploader.run(), 1);
    expect(store.objects.keys, [path(sent)]);
    expect(await uploader.run(), 0);
    expect(store.uploads, 1);
    // The one whose file is gone was never sent: it still shows as waiting.
    expect(await photos.watchPendingUploads().first, [(gone, null)]);
  });

  test('already stored counts as done', () async {
    final key = await photo();
    store.objects[path(key)] = jpeg;
    expect(await uploader.run(), 0);
    expect(await photos.watchPendingUploads().first, isEmpty);
  });

  test('cap reached leaves it pending with reason cap', () async {
    store.cap = 0;
    final key = await photo();
    expect(await uploader.run(), 0);
    expect(await photos.watchPendingUploads().first, [(key, 'cap')]);
  });

  test('past the cap the run stops at the first refusal', () async {
    store.cap = 0;
    for (var i = 0; i < 3; i++) {
      await photo();
    }
    expect(await uploader.run(), 0);
    expect(store.uploads, 1);
    expect(await photos.watchPendingUploads().first, hasLength(3));
  });

  test('after a cap refusal, runs wait 6 hours before trying again', () async {
    var now = DateTime.utc(2026, 3, 20, 8);
    uploader = PhotoUploader(db, store, files, session, now: () => now);
    store.cap = 0;
    await photo();
    await uploader.run();
    store.cap = 300;
    now = now.add(const Duration(hours: 5));
    expect(await uploader.run(), 0);
    expect(store.uploads, 1);
    now = now.add(const Duration(hours: 2));
    expect(await uploader.run(), 1);
  });

  test(
    'an unexpected error on one photo is recorded, the others still go',
    () async {
      final bad = await photo();
      final good = await photo();
      store.broken.add(path(bad));
      expect(await uploader.run(), 1);
      expect(store.objects.keys, [path(good)]);
      expect(await photos.watchPendingUploads().first, [(bad, 'failed')]);
    },
  );

  test('offline stops the run and loses nothing', () async {
    final a = await photo();
    final b = await photo();
    store.offline = true;
    expect(await uploader.run(), 0);
    expect(
      {for (final (k, _) in await photos.watchPendingUploads().first) k},
      {a, b},
    );
    expect((await files.ownFile(a)).existsSync(), isTrue);
  });

  test('fetch caches a download and returns null offline', () async {
    store.objects['${session.associationId}/k1.jpg'] = jpeg;
    final f = await files.fetch(
      'k1',
      associationId: session.associationId,
      store: store,
    );
    expect(f!.readAsBytesSync(), jpeg);
    expect(f.path, (await files.cacheFile('k1')).path);
    store.offline = true;
    expect(
      await files.fetch(
        'k2',
        associationId: session.associationId,
        store: store,
      ),
      isNull,
    );
    // The cached one still opens offline.
    expect(
      (await files.fetch(
        'k1',
        associationId: session.associationId,
        store: store,
      ))!.path,
      f.path,
    );
  });
}
