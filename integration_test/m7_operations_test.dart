import 'dart:io';

import 'package:dobo/app.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/feed_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/db/repositories/reading_repository.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/reports/share_report.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers.dart';

/// M7 milestone walk-through on a device, against the real database. Run it
/// in airplane mode on a freshly cleared app:
///   adb shell pm clear mg.dobo.dobo
///   flutter test integration_test/m7_operations_test.dart -d DEVICE
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));
  final shared = <File>[];

  testWidgets('prepare a pond, track feed, harvest, sell and trace a batch', (
    tester,
  ) async {
    final overrides = [
      reportSharerProvider.overrideWithValue((f) async => shared.add(f)),
    ];
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const DoboApp()),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DoboApp)),
    );
    final db = container.read(databaseProvider);

    // Setup: E1 (20 × 15 m, empty) and E2 with L1, 1 000 fish at 20 g
    // stocked 120 days ago and weighed at 250 g.
    await enterAndSettle(tester, field('Nom du site'), 'Ambohidratrimo');
    await tapAndSettle(tester, find.text('Commencer'));
    final session = container.read(sessionProvider).requireValue!;
    expect(session.isSales, isTrue); // the phone's admin, off the server
    final today = farmDate(DateTime.now().toUtc());
    DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);
    final ponds = container.read(pondRepositoryProvider);
    final e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
        lengthM: 20,
        widthM: 15,
      ),
    );
    final e2 = await ponds.create(
      const PondInput(
        code: 'E2',
        colour: PondColour.green,
        role: PondRole.growout,
      ),
    );
    final l1 = await container
        .read(batchRepositoryProvider)
        .stockBatch(
          StockInput(
            code: 'L1',
            pondId: e2,
            date: daysAgo(120),
            count: 1000,
            avgWeightMg: 20000,
          ),
        );
    await container
        .read(readingRepositoryProvider)
        .addSample(
          SampleInput(
            batchId: l1,
            pondId: e2,
            date: daysAgo(5),
            fishCount: 40,
            totalWeightG: 10000,
          ),
        );
    await container
        .read(prepRepositoryProvider)
        .record(e1, PrepStep.drain, on: daysAgo(6));
    await tester.pumpAndSettle();

    // 1. The drying alert opens E1's checklist; tick the rest; ready.
    await tapAndSettle(tester, tab('Alertes'));
    await tapAndSettle(tester, find.textContaining('fissures'));
    expect(find.text('Préparation E1'), findsOneWidget);
    expect(find.text('Chaux vive : 30–60 kg pour 300 m²'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const ValueKey('done-dry')));
    await tapAndSettle(tester, inDialog('Enregistrer'));
    await tapAndSettle(tester, find.byKey(const ValueKey('done-treat')));
    await tapAndSettle(tester, inDialog('Chaux vive'));
    await enterAndSettle(tester, field('Dose utilisée'), '45');
    await tapAndSettle(tester, inDialog('Enregistrer'));
    await tapAndSettle(tester, find.byKey(const ValueKey('done-fertilise')));
    await tapAndSettle(tester, inDialog('Enregistrer'));
    await tapAndSettle(tester, find.byKey(const ValueKey('done-fill')));
    await tapAndSettle(tester, inDialog('Enregistrer'));
    await tapAndSettle(tester, find.text('Prêt à empoissonner'));
    expect(find.textContaining("Le repos n'est pas fini"), findsOneWidget);
    await tapAndSettle(tester, inDialog('Prêt à empoissonner'));
    expect((await ponds.get(e1)).status, PondStatus.ready);

    // 2. A 50 kg lot made 65 days ago: the feed-age warning.
    await container
        .read(feedRepositoryProvider)
        .deliver(
          FeedDeliveryInput(
            date: daysAgo(2),
            phase: Phase.growout,
            weightG: 50000,
            manufacturedOn: daysAgo(65),
            label: 'Sacs bleus',
          ),
        );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, tab('Alertes'));
    expect(find.textContaining('vieillit'), findsOneWidget);

    // 3. The worker logs E2 with 6 kg: 44 kg left.
    await tapAndSettle(tester, tab('Plus'));
    await tapAndSettle(tester, find.text('Mode ouvrier'));
    await tapAndSettle(tester, find.text('E2'));
    expect(find.byKey(const ValueKey('feed-lot')), findsNothing);
    await enterAndSettle(tester, field('Sakafo nomena'), '6');
    await tapAndSettle(tester, find.text('Tehirizo'));
    await tapAndSettle(tester, find.byTooltip('Hiala'));
    await tapAndSettle(tester, find.text('Aliment'));
    expect(find.text('44 kg'), findsWidgets);

    // 4. Harvest E2, final: 950 fish, 240 kg. L1 closes, E2 empties.
    container.read(routerProvider).go('/more/batches/$l1');
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Récolter'));
    await enterAndSettle(tester, field('Nombre de poissons'), '950');
    await enterAndSettle(tester, field('Poids total'), '240');
    await tapAndSettle(tester, find.text("Finale (l'étang est vidé)"));
    expect(find.textContaining('50 poissons non retrouvés'), findsOneWidget);
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(find.text('Clôturé'), findsOneWidget);
    expect((await ponds.get(e2)).status, PondStatus.empty);

    // 5. Sell 200 kg fresh to a new customer.
    await tapAndSettle(tester, find.text('Vendre'));
    await tapAndSettle(tester, find.text('Nouveau client'));
    await enterAndSettle(tester, field('Nom'), 'Marché Antsirabe');
    await tapAndSettle(tester, find.text('Marché'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    await enterAndSettle(tester, field('Poids vendu'), '200');
    await tapAndSettle(tester, find.text('Frais'));
    await tapAndSettle(tester, find.text('Enregistrer'));
    expect(
      find.textContaining('Marché Antsirabe · Frais · 200 kg'),
      findsOneWidget,
    );

    // 6. The traceability sheet (the share sheet is stubbed).
    await tester.tap(find.byTooltip('Fiche de traçabilité'));
    for (var i = 0; i < 100 && shared.isEmpty; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    await tester.pumpAndSettle();
    expect(shared.single.path, contains('tracabilite-L1-'));
    expect(
      String.fromCharCodes(shared.single.readAsBytesSync().take(4)),
      '%PDF',
    );

    // 7. A visit's report: feed stock 44 kg, no fish left in E2.
    await tapAndSettle(tester, tab('Visite'));
    await tapAndSettle(tester, find.text('Commencer la visite'));
    await tapAndSettle(tester, find.text('Terminer la visite'));
    await tapAndSettle(tester, inDialog('Terminer la visite'));
    await tapAndSettle(tester, find.text('Publier'));
    final report = await db.select(db.visitReports).getSingle();
    final content = ReportContent.decode(report.content);
    expect(content.format, 2);
    expect(content.feedStock!.onHandG, 44000);
    expect(content.growth, isEmpty);
  });
}
