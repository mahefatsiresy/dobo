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

/// `list` for the ponds list, or a pond code (E2) for that pond's page.
const _page = String.fromEnvironment('DEMO_PAGE', defaultValue: 'list');

/// The app on the demo farm, for screenshots of the redesigned screens
/// (tool/design_screenshots.sh). The farm lives in memory: the device's own
/// records are untouched. Never part of a release build.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsApp.debugAllowBannerOverride = false;
  final db = AppDatabase(NativeDatabase.memory());
  await SetupRepository(db).completeSetup(
    siteName: 'Ambohidratrimo',
    role: MemberRole.member,
    isAdmin: true,
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
  if (_page != 'list') {
    // After the router's own start-up redirect to the ponds list.
    await Future<void>.delayed(const Duration(seconds: 2));
    container.read(routerProvider).go('/ponds/${farm[_page]}');
  }
}
