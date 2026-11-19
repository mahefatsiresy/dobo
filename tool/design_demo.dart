import 'package:dobo/app.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/account/account_locale.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/router.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../test/demo_farm.dart';

const _locale = String.fromEnvironment('DEMO_LOCALE', defaultValue: 'fr');

/// `list` for the ponds list, a pond code (E2) for that pond's page,
/// `worker` for the worker home, or `log-E1` for E1's daily log.
const _page = String.fromEnvironment('DEMO_PAGE', defaultValue: 'list');

/// The app on the demo farm, for screenshots of the redesigned screens
/// (tool/design_screenshots.sh). The farm lives in memory: the device's own
/// records are untouched. Never part of a release build.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsApp.debugAllowBannerOverride = false;
  final db = AppDatabase(NativeDatabase.memory());
  // Worker pages are seen as the worker sees them.
  final worker = _page == 'worker' || _page.startsWith('log-');
  await SetupRepository(db).completeSetup(
    siteName: 'Ambohidratrimo',
    role: worker ? MemberRole.worker : MemberRole.member,
    isAdmin: !worker,
  );
  final farm = await seedDemoFarm(db);
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => demoNow),
      accountLocaleProvider.overrideWith(
        (ref) => Stream.value(const Locale(_locale)),
      ),
    ],
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const DoboApp()),
  );
  if (_page == 'list') return;
  final path = switch (_page) {
    'worker' => '/worker',
    _ when _page.startsWith('log-') =>
      '/log/${_pond(farm, _page.substring(4))}',
    _ => '/ponds/${_pond(farm, _page)}',
  };
  // Open the page once the router has settled on its landing page (the
  // ponds list, or the worker home) after its start-up redirect.
  final router = container.read(routerProvider);
  for (var i = 0; i < 100; i++) {
    final at = router.routerDelegate.currentConfiguration.uri.path;
    if (at == '/ponds' || at == '/worker') break;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  router.go(path);
}

/// The demo pond's id; a code the demo farm lacks is a mistake, not an
/// empty page.
String _pond(DemoFarm farm, String code) =>
    farm[code] ??
    (throw ArgumentError.value(code, 'DEMO_PAGE', 'no such pond'));
