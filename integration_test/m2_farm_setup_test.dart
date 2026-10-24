import 'package:dobo/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers.dart';

/// M2 milestone walk-through on a device, against the real database. Run it
/// in airplane mode on a freshly cleared app:
///   adb shell pm clear mg.dobo.dobo
///   flutter test integration_test/m2_farm_setup_test.dart -d DEVICE
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> choose(WidgetTester tester, String label, String item) async {
    await tapAndSettle(tester, find.text(label));
    await tapAndSettle(tester, find.textContaining(item).last);
  }

  Future<void> addPond(
    WidgetTester tester,
    String code, {
    String? role,
    bool ready = false,
  }) async {
    await tapAndSettle(tester, find.text('Ajouter un étang'));
    await enterAndSettle(tester, field('Code'), code);
    if (role != null) await choose(tester, 'Grossissement', role);
    await enterAndSettle(tester, field('Longueur'), '25');
    await enterAndSettle(tester, field('Largeur'), '20');
    if (ready) await choose(tester, 'Vide', 'Prêt');
    await tapAndSettle(tester, find.text('Enregistrer'));
  }

  testWidgets('set up, stock, move, correct', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DoboApp()));
    await tester.pumpAndSettle();

    await enterAndSettle(tester, field('Nom du site'), 'Ambohidratrimo');
    await tapAndSettle(tester, find.text('Commencer'));

    await addPond(tester, 'Q1', role: 'Quarantaine', ready: true);
    await addPond(tester, 'E1', ready: true);
    await addPond(tester, 'E2');
    expect(find.text('Q1'), findsOneWidget);
    expect(find.text('E2'), findsOneWidget);

    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Personnes'));
    await tapAndSettle(tester, find.text('Ajouter'));
    await enterAndSettle(tester, field('Nom'), 'Rakoto');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Rakoto'), findsOneWidget);

    await tapAndSettle(tester, find.text('Étangs'));
    await tapAndSettle(tester, find.text('Q1'));
    await tapAndSettle(tester, find.text('Empoissonner'));
    await enterAndSettle(tester, field("Nombre d'alevins"), '1000');
    await enterAndSettle(tester, field('Poids moyen'), '12,5');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Quarantaine'), findsOneWidget);

    await tapAndSettle(tester, find.text('Étangs'));
    await tapAndSettle(tester, find.text('Q1'));
    await tapAndSettle(tester, find.text('Transférer'));
    await choose(tester, "Vers l'étang", 'E1 ·');
    await enterAndSettle(tester, field('Nombre de poissons'), '1000');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Actif'), findsOneWidget);

    await tapAndSettle(tester, find.text('Corriger').last);
    await enterAndSettle(tester, field("Nombre d'alevins"), '1100');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.textContaining('1\u202f100'), findsWidgets);

    // The correction leaves 100 fish in Q1; E1 keeps the 1 000 moved.
    await tapAndSettle(tester, find.text('Étangs'));
    expect(find.text('100'), findsOneWidget);
    expect(find.text('1\u202f000'), findsOneWidget);
  });
}
