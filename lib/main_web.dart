import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'console/console_app.dart';
import 'sync/server_config.dart';

/// The web console (SPEC F16): `flutter run -d chrome -t lib/main_web.dart
/// --dart-define-from-file=env/host.json`. Online only; nothing reachable
/// from here may import phone-only code (test/console/web_safe_imports_test).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (serverConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
  runApp(const ProviderScope(child: ConsoleApp()));
}
