import 'dart:io';

import '../sync/photo_store.dart';
import '../sync/sync_api.dart';

/// Where photo files live (SPEC §8): the phone's own in the app's documents
/// (kept until deleted), downloaded ones in its cache (the system may clear
/// them; they come back from Storage). Sync file calls: a 250 KB write is
/// quick even on an old phone.
class PhotoFiles {
  PhotoFiles({required this.docs, required this.cache});

  final Future<Directory> Function() docs;
  final Future<Directory> Function() cache;

  /// The file of a photo taken on this phone.
  Future<File> ownFile(String key) async =>
      File('${await _dir(docs)}/$key.jpg');

  /// The file a downloaded photo is kept in.
  Future<File> cacheFile(String key) async =>
      File('${await _dir(cache)}/$key.jpg');

  /// The photo's file on this phone, own first, or null.
  Future<File?> existingFile(String key) async {
    final own = await ownFile(key);
    if (own.existsSync()) return own;
    final cached = await cacheFile(key);
    return cached.existsSync() ? cached : null;
  }

  /// The photo's file, downloaded into the cache when it isn't here yet;
  /// null when it can't be had (offline, not sent, no server).
  Future<File?> fetch(
    String key, {
    required String associationId,
    PhotoStore? store,
  }) async {
    final here = await existingFile(key);
    if (here != null || store == null) return here;
    try {
      final bytes = await store.download(photoPath(associationId, key));
      if (bytes == null) return null;
      return (await cacheFile(key))..writeAsBytesSync(bytes, flush: true);
    } on SyncOffline {
      return null;
    }
  }

  Future<String> _dir(Future<Directory> Function() base) async {
    final dir = Directory('${(await base()).path}/photos');
    dir.createSync(recursive: true);
    return dir.path;
  }
}
