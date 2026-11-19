import 'package:dobo/app.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/account/account_locale.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../test/demo_farm.dart';

const _locale = String.fromEnvironment('DEMO_LOCALE', defaultValue: 'fr');

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
  await seedDemoFarm(db);
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => demoNow),
        accountLocaleProvider.overrideWith(
          (ref) => Stream.value(const Locale(_locale)),
        ),
      ],
      child: const DoboApp(),
    ),
  );
}
