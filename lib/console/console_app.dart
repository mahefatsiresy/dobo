import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/mg_fallback.dart';
import '../locale_controller.dart';
import 'console_providers.dart';
import 'console_router.dart';
import 'idle_guard.dart';

/// The web console (SPEC F16): the app's translations and theme, its own
/// desktop pages.
class ConsoleApp extends ConsumerWidget {
  const ConsoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).consoleTitle,
      routerConfig: ref.watch(consoleRouterProvider),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      // An admin's session ends after 30 minutes without use (SPEC F16).
      builder: (context, child) {
        final signedIn = ref.watch(consoleSessionProvider).value != null;
        return IdleGuard(
          enabled: signedIn,
          onIdle: () => ref
              .read(consoleSessionProvider.notifier)
              .signOut(notice: 'idle'),
          child: child!,
        );
      },
    );
  }
}
