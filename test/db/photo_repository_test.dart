import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/photo_repository.dart';
import 'package:dobo/db/repositories/visit_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/db/photo_files.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late Directory docs, cache;
  late PhotoFiles files;
  late PhotoRepository photos;
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 3]);

  setUp(() async {
    (db, session) = await setUpFarm();
    docs = Directory.systemTemp.createTempSync('dobo-docs');
    cache = Directory.systemTemp.createTempSync('dobo-cache');
    files = PhotoFiles(docs: () async => docs, cache: () async => cache);
    photos = PhotoRepository(db, session, files);
  });
  tearDown(() async {
    await db.close();
    docs.deleteSync(recursive: true);
    cache.deleteSync(recursive: true);
  });

  test('add writes the file then the row', () async {
    final key = await photos.add(
      owner: PhotoOwner.visit,
      ownerId: 'v1',
      jpeg: jpeg,
    );
    final file = await files.ownFile(key);
    expect(file.readAsBytesSync(), jpeg);
    final row = await db.select(db.photos).getSingle();
    expect(
      (row.id, row.photoKey, row.ownerKind, row.ownerId, row.bytes),
      (key, key, PhotoOwner.visit, 'v1', jpeg.length),
    );
    expect(row.upload, isFalse);
  });

  test('a failed file write leaves no row', () async {
    final blocked = File('${docs.path}/blocked')..writeAsStringSync('x');
    final broken = PhotoRepository(
      db,
      session,
      PhotoFiles(
        docs: () async => Directory(blocked.path),
        cache: () async => cache,
      ),
    );
    await expectLater(
      broken.add(owner: PhotoOwner.visit, ownerId: 'v1', jpeg: jpeg),
      throwsA(isA<FileSystemException>()),
    );
    expect(await db.select(db.photos).get(), isEmpty);
  });

  test('setUpload supersedes and keeps the key', () async {
    final key = await photos.add(
      owner: PhotoOwner.visit,
      ownerId: 'v1',
      jpeg: jpeg,
    );
    await photos.setUpload(key, true);
    final current = await photos.watchFor(PhotoOwner.visit, 'v1').first;
    expect(current.single.photoKey, key);
    expect(current.single.upload, isTrue);
    expect(current.single.id, isNot(key));
  });

  test('setUpload on a phone without the file throws', () async {
    final key = await photos.add(
      owner: PhotoOwner.visit,
      ownerId: 'v1',
      jpeg: jpeg,
    );
    (await files.ownFile(key)).deleteSync();
    await expectLater(photos.setUpload(key, true), throwsStateError);
  });

  test('delete tombstones and removes the file', () async {
    final key = await photos.add(
      owner: PhotoOwner.visit,
      ownerId: 'v1',
      jpeg: jpeg,
    );
    await photos.delete(key);
    expect(await photos.watchFor(PhotoOwner.visit, 'v1').first, isEmpty);
    expect((await files.ownFile(key)).existsSync(), isFalse);
    expect(await db.select(db.photos).get(), hasLength(2));
  });

  test('watchFor follows an observation\'s correction', () async {
    final visitId = await VisitRepository(db, session).start();
    final obs = ObservationRepository(db, session, visitId: visitId);
    final first = await obs.addObservation(
      category: ObservationCategory.dike,
      ok: false,
      note: 'Fuite',
    );
    final key = await photos.add(
      owner: PhotoOwner.observation,
      ownerId: first,
      jpeg: jpeg,
    );
    final corrected = await obs.correctObservation(
      first,
      category: ObservationCategory.dike,
      ok: false,
      note: 'Grosse fuite',
    );
    final got = await photos.watchFor(PhotoOwner.observation, corrected).first;
    expect(got.single.photoKey, key);
  });

  test('existingFile prefers the own file, then the cache', () async {
    expect(await files.existingFile('k'), isNull);
    final cached = await files.cacheFile('k');
    cached.writeAsBytesSync(jpeg);
    expect((await files.existingFile('k'))!.path, cached.path);
    final own = await files.ownFile('k');
    own.writeAsBytesSync(jpeg);
    expect((await files.existingFile('k'))!.path, own.path);
  });
}
