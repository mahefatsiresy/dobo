import 'dart:typed_data';

import 'package:dobo/sync/photo_store.dart';
import 'package:dobo/sync/sync_api.dart';

/// Storage in memory, with a cap and an off switch.
class FakePhotoStore implements PhotoStore {
  FakePhotoStore({this.cap = 300});

  final Map<String, Uint8List> objects = {};
  int cap;
  bool offline = false;
  int uploads = 0;

  /// Paths whose upload fails with an unexpected server error.
  final Set<String> broken = {};

  @override
  Future<void> upload(String path, Uint8List bytes) async {
    if (offline) throw SyncOffline();
    uploads++;
    if (broken.contains(path)) throw StateError('server error');
    if (objects.containsKey(path)) throw PhotoAlreadyStored();
    if (objects.length >= cap) throw PhotoCapReached();
    objects[path] = bytes;
  }

  @override
  Future<Uint8List?> download(String path) async {
    if (offline) throw SyncOffline();
    return objects[path];
  }
}
