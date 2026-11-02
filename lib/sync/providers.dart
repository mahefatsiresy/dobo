import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database_provider.dart';

import 'auth_gateway.dart';
import 'photo_store.dart';
import 'server_config.dart';
import 'supabase_photo_store.dart';
import 'supabase_auth_gateway.dart';
import 'supabase_sync_api.dart';
import 'sync_api.dart';
import 'sync_status_repository.dart';

/// Accounts on the server; null in a build with no server configured.
final authGatewayProvider = Provider<AuthGateway?>(
  (ref) =>
      serverConfigured ? SupabaseAuthGateway(Supabase.instance.client) : null,
);

/// The sync transport; null in a build with no server configured.
final syncApiProvider = Provider<SyncApi?>(
  (ref) => serverConfigured ? SupabaseSyncApi(Supabase.instance.client) : null,
);

/// Photo files on the server; null in a build with no server configured.
final photoStoreProvider = Provider<PhotoStore?>(
  (ref) =>
      serverConfigured ? SupabasePhotoStore(Supabase.instance.client) : null,
);

final syncStatusRepositoryProvider = Provider<SyncStatusRepository>(
  (ref) => SyncStatusRepository(ref.watch(databaseProvider)),
);

final syncCountsProvider = StreamProvider<({int pending, int rejected})>(
  (ref) => ref.watch(syncStatusRepositoryProvider).watchCounts(),
);
