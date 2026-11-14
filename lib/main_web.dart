import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'console/console_app.dart';
import 'console/console_providers.dart';
import 'console/data/browser_device.dart';
import 'console/data/supabase_console_api.dart';
import 'sync/server_config.dart';

/// The web console (SPEC F16): `flutter run -d chrome -t lib/main_web.dart
/// --dart-define-from-file=env/host.json`. Online only; nothing reachable
/// from here may import phone-only code (test/console/web_safe_imports_test).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!serverConfigured) {
    // The console is online only: it has nothing to show without a server.
    runApp(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Text('SUPABASE_URL ?')),
      ),
    );
    return;
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  final deviceId = await browserDeviceId(await SharedPreferences.getInstance());
  runApp(
    ProviderScope(
      overrides: [
        consoleApiProvider.overrideWithValue(
          SupabaseConsoleApi(Supabase.instance.client, deviceId),
        ),
      ],
      child: const ConsoleApp(),
    ),
  );
}
