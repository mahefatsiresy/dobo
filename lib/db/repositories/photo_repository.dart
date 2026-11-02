import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../database.dart';
import '../events.dart';
import '../ids.dart';
import '../photo_files.dart';
import '../session.dart';

/// Photos on observations, health events and visits (SPEC §8). The file is
/// written before the row, so a row always has its file on the phone that
/// took it.
class PhotoRepository {
  PhotoRepository(this.db, this.session, this.files);

  final AppDatabase db;
  final Session session;
  final PhotoFiles files;

  /// Keeps [jpeg] (already compressed) for [owner] [ownerId]; returns the
  /// photo's key.
  Future<String> add({
    required PhotoOwner owner,
    required String ownerId,
    required Uint8List jpeg,
  }) async {
    final key = newId();
    (await files.ownFile(key)).writeAsBytesSync(jpeg, flush: true);
    await db
        .into(db.photos)
        .insert(
          PhotosCompanion.insert(
            id: Value(key),
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            recordedAt: utcNow(),
            ownerKind: owner,
            ownerId: ownerId,
            photoKey: key,
            bytes: jpeg.length,
          ),
        );
    return key;
  }

  /// Marks the photo to go to Storage, or not. Only the phone holding the
  /// file can: throws [StateError] elsewhere.
  Future<void> setUpload(String photoKey, bool upload) async {
    if (!(await files.ownFile(photoKey)).existsSync()) {
      throw StateError('The photo $photoKey is not on this phone');
    }
    final row = await _current(photoKey);
    await db.supersede(
      db.photos,
      row.id,
      PhotosCompanion.insert(
        associationId: session.associationId,
        enteredBy: session.userId,
        deviceId: session.deviceId,
        recordedAt: utcNow(),
        ownerKind: row.ownerKind,
        ownerId: row.ownerId,
        photoKey: photoKey,
        upload: Value(upload),
        bytes: row.bytes,
      ),
    );
  }

  /// Deletes the photo: a tombstone, and the file on this phone. A copy
  /// already in Storage stays there (plan Decision 10).
  Future<void> delete(String photoKey) async {
    final row = await _current(photoKey);
    await db.tombstone(db.photos, row.id, session);
    final file = await files.ownFile(photoKey);
    if (file.existsSync()) file.deleteSync();
  }

  /// [owner] [ownerId]'s current photos, oldest first, including those on
  /// earlier versions of a corrected observation.
  Stream<List<Photo>> watchFor(PhotoOwner owner, String ownerId) async* {
    final ids = owner == PhotoOwner.observation
        ? await db.chainIds(db.observations, ownerId)
        : {ownerId};
    yield* (db.select(db.photos)
          ..where(
            (p) =>
                isCurrentEvent(db.photos) &
                p.ownerKind.equalsValue(owner) &
                p.ownerId.isIn(ids),
          )
          ..orderBy([(p) => OrderingTerm.asc(p.recordedAt)]))
        .watch();
  }

  /// Every current photo, oldest first.
  Stream<List<Photo>> watchAll() =>
      (db.select(db.photos)
            ..where((_) => isCurrentEvent(db.photos))
            ..orderBy([(p) => OrderingTerm.asc(p.recordedAt)]))
          .watch();

  /// This phone's photos marked to send and not sent yet, with the reason
  /// the last try failed (`cap`), if any.
  Stream<List<(String, String?)>> watchPendingUploads() {
    final u = db.photoUploads;
    final q =
        db.select(db.photos).join([
            leftOuterJoin(u, u.photoKey.equalsExp(db.photos.photoKey)),
          ])
          ..where(
            isCurrentEvent(db.photos) &
                db.photos.upload.equals(true) &
                db.photos.deviceId.equals(session.deviceId) &
                u.uploadedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(db.photos.recordedAt)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          (r.readTable(db.photos).photoKey, r.readTableOrNull(u)?.error),
      ],
    );
  }

  Future<Photo> _current(String photoKey) =>
      (db.select(db.photos)
            ..where(
              (p) => isCurrentEvent(db.photos) & p.photoKey.equals(photoKey),
            )
            ..limit(1))
          .getSingle();
}
