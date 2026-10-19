import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'l10n/mg_fallback.dart';
import 'locale_controller.dart';
import 'router.dart';

class DoboApp extends ConsumerWidget {
  const DoboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
