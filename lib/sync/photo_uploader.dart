import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/events.dart';
import '../db/ids.dart';
import '../db/photo_files.dart';
import '../db/session.dart';
import 'photo_store.dart';
import 'sync_api.dart';

/// Sends the photos marked "upload" whose file is on this phone (plan
/// Decision 11). Runs after each sync; a photo it can't send stays on the
/// phone, waiting, with the reason.
class PhotoUploader {
  PhotoUploader(this.db, this.store, this.files, this.session);

  final AppDatabase db;
  final PhotoStore store;
  final PhotoFiles files;
  final Session session;

  /// Returns how many photos it sent.
  Future<int> run() async {
    final done = {
      for (final u in await (db.select(
        db.photoUploads,
      )..where((u) => u.uploadedAt.isNotNull())).get())
        u.photoKey,
    };
    final marked =
        await (db.select(db.photos)..where(
              (p) =>
                  isCurrentEvent(db.photos) &
                  p.upload.equals(true) &
                  p.deviceId.equals(session.deviceId),
            ))
            .get();
    var sent = 0;
    for (final p in marked) {
      if (done.contains(p.photoKey)) continue;
      final file = await files.ownFile(p.photoKey);
      if (!file.existsSync()) continue;
      try {
        await store.upload(
          photoPath(session.associationId, p.photoKey),
          file.readAsBytesSync(),
        );
        sent++;
        await _record(p.photoKey, uploaded: true);
      } on PhotoAlreadyStored {
        await _record(p.photoKey, uploaded: true);
      } on PhotoCapReached {
        await _record(p.photoKey, error: 'cap');
      } on SyncOffline {
        break;
      }
    }
    return sent;
  }

  Future<void> _record(String key, {bool uploaded = false, String? error}) => db
      .into(db.photoUploads)
      .insertOnConflictUpdate(
        PhotoUploadsCompanion.insert(
          photoKey: key,
          uploadedAt: Value(uploaded ? utcNow() : null),
          error: Value(error),
        ),
      );
}
