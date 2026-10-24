import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('boots in French on the ponds tab', (tester) async {
    final db = testDatabase();
    await SetupRepository(db).completeSetup(siteName: 'Ambohidratrimo');
    await pumpApp(tester, db);
    expect(find.text('Étangs'), findsWidgets);
    expect(find.text('Plus'), findsOneWidget);
  });

  testWidgets('Malagasy falls back to French for Material labels',
      (tester) async {
    final db = testDatabase();
    await SetupRepository(db).completeSetup(siteName: 'Ambohidratrimo');
    await pumpApp(tester, db);
    appContainer(tester)
        .read(localeControllerProvider.notifier)
        .set(const Locale('mg'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final ctx = tester.element(find.byType(NavigationBar));
    expect(Localizations.localeOf(ctx), const Locale('mg'));
    final fr =
        await GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
    expect(MaterialLocalizations.of(ctx).cancelButtonLabel,
        fr.cancelButtonLabel);
  });
}
