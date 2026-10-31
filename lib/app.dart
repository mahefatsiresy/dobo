import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/account/account_locale.dart';
import 'features/common/farm_today.dart';
import 'db/repositories/providers.dart';
import 'sync/sync_controller.dart';
import 'l10n/app_localizations.dart';
import 'l10n/mg_fallback.dart';
import 'locale_controller.dart';
import 'router.dart';

class DoboApp extends ConsumerStatefulWidget {
  const DoboApp({super.key});

  @override
  ConsumerState<DoboApp> createState() => _DoboAppState();
}

class _DoboAppState extends ConsumerState<DoboApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the background, maybe the next morning: today may have moved.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(farmTodayProvider.notifier).refresh();
        ref.read(syncControllerProvider.notifier)
          ..resume()
          ..syncNow();
      },
      onPause: () => ref.read(syncControllerProvider.notifier).pause(),
    );
    // Sync at start and after every sign-in (plan Decision 11).
    ref.listenManual(sessionProvider, (previous, next) {
      final session = next.value;
      if (session != null && session != previous?.value) {
        ref.read(syncControllerProvider.notifier)
          ..resume()
          ..syncNow();
      }
    }, fireImmediately: true);
    // Each account brings its language; a member's worker mode switches
    // it by hand meanwhile.
    ref.listenManual(accountLocaleProvider, (previous, next) {
      final locale = next.value;
      if (locale != null && locale != previous?.value) {
        ref.read(localeControllerProvider.notifier).set(locale);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: ref.watch(routerProvider),
      locale: ref.watch(localeControllerProvider),
      supportedLocales: const [Locale('fr'), Locale('mg')],
      // The Malagasy fallbacks must come before the Global delegates.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...mgFallbackDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
