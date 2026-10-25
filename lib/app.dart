import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/common/farm_today.dart';
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
      onResume: () => ref.read(farmTodayProvider.notifier).refresh(),
    );
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
