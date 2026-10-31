import 'package:dobo/app.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/features/daily_log/stop_feeding_sign.dart';
import 'package:dobo/features/readings/sample_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers.dart';

/// M5 milestone walk-through on a device, against the real database. Run it
/// in airplane mode on a freshly cleared app:
///   adb shell pm clear mg.dobo.dobo
///   flutter test integration_test/m5_guidance_test.dart -d DEVICE
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  testWidgets('alerts lead to the fix, the dashboard and worker advice', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DoboApp()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DoboApp)),
    );

    // Setup: a site and pond E1 (500 m²), batch L1 stocked 15 days ago at
    // 10 g, fed 14 kg since.
    await enterAndSettle(tester, field('Nom du site'), 'Ambohidratrimo');
    await tapAndSettle(tester, find.text('Commencer'));
    await tapAndSettle(tester, find.text('Ajouter un étang'));
    await enterAndSettle(tester, field('Code'), 'E1');
    await enterAndSettle(tester, field('Longueur'), '25');
    await enterAndSettle(tester, field('Largeur'), '20');
    await tapAndSettle(tester, find.text('Enregistrer'));
    final today = farmDate(DateTime.now().toUtc());
    DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);
    final e1 =
        (await container.read(pondRepositoryProvider).watchActive().first)
            .single
            .id;
    await container
        .read(batchRepositoryProvider)
        .stockBatch(
          StockInput(
            code: 'L1',
            pondId: e1,
            date: daysAgo(15),
            count: 1000,
            avgWeightMg: 10000,
          ),
        );
    final logs = container.read(dailyLogRepositoryProvider);
    for (var n = 14; n >= 1; n--) {
      await logs.save(
        DailyLogInput(pondId: e1, date: daysAgo(n), feedGivenG: 1000),
      );
    }
    await tester.pumpAndSettle();

    // 1. Sampling and a water check are due.
    await tapAndSettle(tester, tab('Alertes'));
    expect(find.textContaining('échantillonnage à faire'), findsOneWidget);
    expect(find.text("Relevé d'eau à faire"), findsOneWidget);

    // 2. The alert opens the sample form; 40 fish weigh 1,2 kg (30 g).
    await tapAndSettle(tester, find.textContaining('échantillonnage à faire'));
    expect(find.byType(SampleScreen), findsOneWidget);
    await enterAndSettle(tester, field('Poissons pesés'), '40');
    await enterAndSettle(tester, field('Poids total'), '1,2');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.textContaining('échantillonnage à faire'), findsNothing);

    // The pond page: FCR of the period and the weight chart. 14 kg for
    // 20 kg gained.
    await tapAndSettle(tester, tab('Étangs'));
    await tapAndSettle(tester, find.text('E1'));
    expect(find.text('IC : 0,7'), findsOneWidget);
    expect(find.text('Survie : 100 %'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Poids moyen (g)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    // 3. A reading with 2 mg/L oxygen: one danger on the Alerts tab.
    await tester.scrollUntilVisible(
      find.text("Relevé d'eau"),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapAndSettle(tester, find.text("Relevé d'eau"));
    await enterAndSettle(tester, field('Oxygène dissous'), '2');
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.widgetWithText(Badge, '1'),
      ),
      findsOneWidget,
    );

    // 4. In worker mode E1's tile says not to feed.
    await tapAndSettle(tester, tab('Plus'));
    await tapAndSettle(tester, find.text('Mode ouvrier'));
    expect(find.byType(StopFeedingSign), findsOneWidget);

    // 5. The worker logs 20 deaths: a mortality spike for the members.
    await tapAndSettle(tester, find.text('E1'));
    await enterAndSettle(tester, field('Sakafo nomena'), '0');
    await enterAndSettle(tester, field('Maty'), '20');
    await tapAndSettle(tester, find.text('Tehirizo'));
    await tapAndSettle(tester, find.byTooltip('Hiala'));
    await tapAndSettle(tester, tab('Alertes'));
    expect(find.textContaining('morts le'), findsOneWidget);
  });
}
