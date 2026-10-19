import 'package:dobo/app.dart';
import 'package:dobo/features/home/home_screen.dart';
import 'package:dobo/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots in French', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DoboApp()));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue'), findsOneWidget);
  });

  testWidgets('Malagasy shows mg strings and French Material labels',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DoboApp()));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(DoboApp)));
    container.read(localeControllerProvider.notifier).set(const Locale('mg'));
    await tester.pumpAndSettle();
    expect(find.text('Tongasoa'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final ctx = tester.element(find.byType(HomeScreen));
    final fr =
        await GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
    expect(MaterialLocalizations.of(ctx).cancelButtonLabel,
        fr.cancelButtonLabel);
  });
}
