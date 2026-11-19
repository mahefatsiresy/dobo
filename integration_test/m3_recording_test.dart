import 'package:dobo/app.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import '../test/helpers.dart';

/// M3 milestone walk-through on a device, against the real database. Run it
/// in airplane mode on a freshly cleared app:
///   adb shell pm clear mg.dobo.dobo
///   flutter test integration_test/m3_recording_test.dart -d DEVICE
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> choose(WidgetTester tester, String label, String item) async {
    await tapAndSettle(tester, find.text(label));
    await tapAndSettle(tester, find.textContaining(item).last);
  }

  Future<void> confirm(WidgetTester tester, String button) => tapAndSettle(
    tester,
    find.descendant(of: find.byType(AlertDialog), matching: find.text(button)),
  );

  /// The Ponds tab returns to the page it was on; a second tap shows the
  /// list.
  Future<void> pondsList(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Étangs'));
    if (find.text('Ajouter un étang').evaluate().isEmpty) {
      await tapAndSettle(tester, find.text('Étangs'));
    }
  }

  testWidgets('log, visit, transcribe, isolate and release', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DoboApp()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DoboApp)),
    );

    // Setup: a site, two ponds, a worker, a batch stocked last month.
    await enterAndSettle(tester, field('Nom du site'), 'Ambohidratrimo');
    await tapAndSettle(tester, find.text('Commencer'));
    for (final code in ['E1', 'E2']) {
      await tapAndSettle(tester, find.text('Ajouter un étang'));
      await enterAndSettle(tester, field('Code'), code);
      await enterAndSettle(tester, field('Longueur'), '25');
      await enterAndSettle(tester, field('Largeur'), '20');
      await choose(tester, 'Vide', 'Prêt');
      await tapAndSettle(tester, find.text('Enregistrer'));
    }
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Personnes'));
    await tapAndSettle(tester, find.text('Ajouter'));
    await enterAndSettle(tester, field('Nom'), 'Rakoto');
    await tapAndSettle(tester, find.text('Enregistrer'));

    await pondsList(tester);
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Empoissonner'));
    await tapAndSettle(
      tester,
      find.ancestor(
        of: find.text("Date d'empoissonnement"),
        matching: find.byType(InkWell),
      ),
    );
    await tapAndSettle(tester, find.byTooltip('Mois précédent'));
    await tapAndSettle(tester, find.text('15'));
    await tapAndSettle(tester, find.text('OK'));
    await enterAndSettle(tester, field("Nombre d'alevins"), '1000');
    await enterAndSettle(tester, field('Poids moyen'), '15');
    await tapAndSettle(tester, find.text('Enregistrer'));

    // The worker logs today in Malagasy: 3 deaths.
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Mode ouvrier'));
    await tapAndSettle(tester, find.text('E1'));
    await enterAndSettle(tester, field('Sakafo nomena'), '0,6');
    await enterAndSettle(tester, field('Maty'), '3');
    await tapAndSettle(tester, find.text('Misy sisa kely'));
    await tapAndSettle(tester, find.text('Mikosokosoka'));
    await tapAndSettle(tester, find.text('Tehirizo'));
    expect(find.byIcon(Icons.task_alt), findsOneWidget);
    await tapAndSettle(tester, find.byTooltip('Hiala'));

    // A visit: water, the sample now due, the five conditions; a summary.
    await tapAndSettle(tester, find.text('Visite'));
    await tapAndSettle(tester, find.text('Commencer la visite'));
    await tapAndSettle(tester, find.byKey(const ValueKey('water-E1')));
    await enterAndSettle(tester, field('pH'), '7,2');
    await enterAndSettle(tester, field('Oxygène dissous'), '4,5');
    await tapAndSettle(tester, find.text('Enregistrer'));
    await tapAndSettle(tester, find.text('Échantillonnage'));
    await enterAndSettle(tester, field('Poissons pesés'), '30');
    await enterAndSettle(tester, field('Poids total'), '0,6');
    await tapAndSettle(tester, find.text('Enregistrer'));
    await tapAndSettle(tester, find.byKey(const ValueKey('conditions-E1')));
    for (final c in ['dike', 'inletScreen', 'predatorNets', 'fence', 'grass']) {
      await tapAndSettle(tester, find.byKey(ValueKey('ok-$c')));
    }
    await tapAndSettle(tester, find.text('Enregistrer'));
    await tapAndSettle(tester, find.text('Terminer la visite'));
    await confirm(tester, 'Terminer la visite');
    // Since M6, ending a visit opens its draft report, where the summary
    // is written (docs/design.md §Step 5).
    expect(find.text('Rapport de visite'), findsOneWidget);
    await enterAndSettle(
      tester,
      find.widgetWithText(TextField, 'Résumé'),
      'Poissons actifs, eau verte',
    );

    // Yesterday's paper sheet: 1 death, as Rakoto.
    final db = container.read(databaseProvider);
    final e1 = (await (db.select(
      db.ponds,
    )..where((p) => p.code.equals('E1'))).getSingle()).id;
    final yesterday = farmDate(DateTime.now().toUtc())
        .subtract(const Duration(days: 1));
    final day = DateFormat('yyyy-MM-dd').format(yesterday);
    container.read(routerProvider).go('/more/transcription?week=$day');
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.byKey(const ValueKey('sheetOf')));
    await tapAndSettle(tester, find.text('Rakoto').last);
    await enterAndSettle(tester, find.byKey(ValueKey('kg-$e1-$day')), '0,5');
    await enterAndSettle(tester, find.byKey(ValueKey('deaths-$e1-$day')), '1');
    await tapAndSettle(tester, find.text('Enregistrer'));

    // A health problem: isolate, then release.
    await pondsList(tester);
    await tapAndSettle(tester, find.text('E1'));
    await tapAndSettle(tester, find.text('Signaler un problème'));
    await tapAndSettle(tester, find.text('Se frotte'));
    await tapAndSettle(tester, find.text("Isoler l'étang"));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Étang isolé'), findsOneWidget);
    await tapAndSettle(tester, find.text("Lever l'isolement"));
    await confirm(tester, "Lever l'isolement");
    expect(find.text('Étang isolé'), findsNothing);

    // 1 000 − 3 − 1 fish, weighed at 20 g, stocked.
    await pondsList(tester);
    expect(find.text('996'), findsOneWidget);
    expect(find.text('Empoissonné'), findsOneWidget);
    await tapAndSettle(tester, find.text('E1'));
    expect(find.textContaining('20 g'), findsWidgets);
  });
}
