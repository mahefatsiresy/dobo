import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateway.dart';
import 'server_config.dart';
import 'supabase_auth_gateway.dart';
import 'supabase_sync_api.dart';
import 'sync_api.dart';

/// Accounts on the server; null in a build with no server configured.
final authGatewayProvider = Provider<AuthGateway?>(
  (ref) =>
      serverConfigured ? SupabaseAuthGateway(Supabase.instance.client) : null,
);

/// The sync transport; null in a build with no server configured.
final syncApiProvider = Provider<SyncApi?>(
  (ref) => serverConfigured ? SupabaseSyncApi(Supabase.instance.client) : null,
);
