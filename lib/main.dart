import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'sync/server_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (serverConfigured) {
    // Reads the saved session from the phone; no network needed.
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
  runApp(const ProviderScope(child: DoboApp()));
}
