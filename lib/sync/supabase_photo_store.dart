import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'photo_store.dart';
import 'server_errors.dart';
import 'sync_api.dart';

/// [PhotoStore] over Supabase Storage's private `photos` bucket; its
/// policies keep each association in its own folder, up to its cap.
class SupabasePhotoStore implements PhotoStore {
  SupabasePhotoStore(this.client);

  final SupabaseClient client;

  StorageFileApi get _bucket => client.storage.from('photos');

  @override
  Future<void> upload(String path, Uint8List bytes) async {
    if (client.auth.currentSession == null) throw SyncSignedOut();
    try {
      await guardServer(
        () => _bucket.uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        ),
      );
    } on StorageException catch (e) {
      final text = '${e.statusCode} ${e.error} ${e.message}'.toLowerCase();
      if (e.statusCode == '409' ||
          text.contains('duplicate') ||
          text.contains('already exists')) {
        throw PhotoAlreadyStored();
      }
      // Row-level security refuses an insert past the association's cap.
      if (e.statusCode == '403' ||
          e.statusCode == '400' && text.contains('row-level security')) {
        throw PhotoCapReached();
      }
      rethrow;
    }
  }

  @override
  Future<Uint8List?> download(String path) async {
    if (client.auth.currentSession == null) return null;
    try {
      return await guardServer(() => _bucket.download(path));
    } on StorageException catch (e) {
      if (e.statusCode == '404' || e.statusCode == '400') return null;
      rethrow;
    }
  }
}
