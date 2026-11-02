import 'dart:typed_data';

/// The object is already in Storage: the upload counts as done.
class PhotoAlreadyStored implements Exception {}

/// The association has stored as many photos as its admin allows.
class PhotoCapReached implements Exception {}

/// Photo files on the server (SPEC §8), at `<association_id>/<key>.jpg`.
/// Throws `SyncOffline` with no network.
abstract interface class PhotoStore {
  /// Throws [PhotoAlreadyStored] or [PhotoCapReached].
  Future<void> upload(String path, Uint8List bytes);

  /// Null when there is no such photo (not sent yet).
  Future<Uint8List?> download(String path);
}

/// Where a photo is kept in Storage.
String photoPath(String associationId, String photoKey) =>
    '$associationId/$photoKey.jpg';

/// The admin setting that caps an association's stored photos, and its
/// default (plan Decision 11; the server uses the same).
const photoUploadCapKey = 'photoUploadCap';
const defaultPhotoUploadCap = 300;
