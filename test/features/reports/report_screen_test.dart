import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/repositories/visit_repository.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/domain/water.dart';
import 'package:dobo/features/reports/report_screen.dart';
import 'package:dobo/features/reports/share_report.dart';
import 'package:dobo/features/sync/backup_actions.dart';
import 'package:dobo/router.dart';
import 'package:drift/drift.dart' show Value;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  DateTime d(int day) => farmDateToUtc(DateTime(2026, 3, day));

  ReportContent full() => ReportContent(
    header: ReportHeader(
      siteName: 'Ambohidratrimo',
      visitDay: d(20),
      memberName: 'Hery',
      groupName: 'Rabe',
      periodFrom: d(13),
      periodTo: d(20),
      builtAt: d(20),
    ),
    summary: 'Digue à reprendre.',
    pondCodes: const {'e1': 'E1', 'e2': 'E2'},
    batchCodes: const {'l1': 'L1'},
    alerts: const [
      Alert(
        AlertKind.waterOutOfRange,
        Severity.danger,
        pondId: 'e1',
        facts: {
          'param': WaterParam.oxygen,
          'value': 2.5,
          'direction': Direction.low,
        },
      ),
    ],
    health: const [
      PondHealth(
        pondId: 'e1',
        deaths: 6,
        byObserver: [
          ObserverDeaths(name: 'Rakoto', deaths: 4),
          ObserverDeaths(name: null, deaths: 2),
        ],
      ),
    ],
    water: [
      PondWater(
        pondId: 'e1',
        at: d(19),
        oxygenMgL: 2.5,
        ph: 7.2,
        issues: const [
          WaterIssue(
            WaterParam.oxygen,
            Severity.danger,
            value: 2.5,
            direction: Direction.low,
          ),
        ],
      ),
      const PondWater(pondId: 'e2'),
    ],
    growth: [
      BatchGrowth(
        batchId: 'l1',
        pondId: 'e1',
        avgWeightG: 30,
        weighedOn: d(15),
        liveCount: 990,
        biomassG: 29700,
        fcrNote: FcrNote.shared,
        survival: 0.99,
      ),
    ],
    feed: const [PondFeed(pondId: 'e1', feedG: 14000)],
    feedTotalG: 14000,
    next: [
      NextItem(kind: NextKind.sample, date: d(29), pondId: 'e1', batchId: 'l1'),
    ],
    observations: const [
      ReportObservation(
        pondId: 'e1',
        category: ObservationCategory.dike,
        ok: false,
        note: 'Fuite côté sud',
      ),
      ReportObservation(
        pondId: 'e1',
        category: ObservationCategory.fence,
        ok: true,
      ),
    ],
  );

  ReportContent empty() => ReportContent(
    header: ReportHeader(
      siteName: 'Ambohidratrimo',
      visitDay: d(20),
      memberName: 'Hery',
      periodFrom: d(13),
      periodTo: d(20),
      builtAt: d(20),
    ),
  );

  /// A report another member published, as a pull stores it.
  Future<String> pulled(
    WidgetTester tester,
    AppDatabase db,
    ReportContent content, {
    String? raw,
  }) async {
    final s = (await SetupRepository(db).currentSession())!;
    final row = await db
        .into(db.visitReports)
        .insertReturning(
          VisitReportsCompanion.insert(
            associationId: s.associationId,
            enteredBy: 'someone-else',
            deviceId: 'other-phone',
            recordedAt: d(20),
            visitId: 'v0',
            siteId: s.siteId,
            periodFrom: d(13),
            periodTo: d(20),
            content: raw ?? content.encode(),
            syncState: const Value(SyncState.synced),
          ),
        );
    await tester.pumpAndSettle();
    return row.id;
  }

  void go(WidgetTester tester, String location) =>
      appContainer(tester).read(routerProvider).go(location);

  appTest('ending a visit opens its draft, publishing shows the report', (
    tester,
    db,
  ) async {
    await tapAndSettle(tester, find.text('Visite'));
    await tapAndSettle(tester, find.text('Démarrer une visite'));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextField, 'Résumé'),
      'Eau verte',
    );
    await tapAndSettle(tester, find.text('Terminer la visite'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Terminer la visite'),
      ),
    );
    // The draft, with the summary from the visit.
    expect(find.text('Rapport de visite'), findsOneWidget);
    final summary = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Résumé'),
    );
    expect(summary.controller!.text, 'Eau verte');
    expect(find.text('Rien à signaler'), findsWidgets);

    await tapAndSettle(tester, find.text('Publier'));
    final r = await db.select(db.visitReports).getSingle();
    expect(ReportContent.decode(r.content).summary, 'Eau verte');
    expect(find.text('Publier'), findsNothing);
    expect(find.text('Eau verte'), findsOneWidget);

    await tapAndSettle(tester, find.text('Rapports'));
    expect(find.text('Brouillon — à publier'), findsNothing);
  });

  appTest('an unread report is bold, opening it clears the badge', (
    tester,
    db,
  ) async {
    await pulled(tester, db, full());
    bool badgeShown() => tester
        .widget<Badge>(find.byKey(const ValueKey('unreadBadge')))
        .isLabelVisible;
    expect(badgeShown(), isTrue);
    await tapAndSettle(tester, find.text('Rapports'));
    final title = tester.widget<Text>(find.text('20/03/2026 · Hery'));
    expect(title.style?.fontWeight, FontWeight.bold);

    await tapAndSettle(tester, find.text('20/03/2026 · Hery'));
    expect(find.text('Digue à reprendre.'), findsOneWidget);
    expect(badgeShown(), isFalse);
  });

  appTest('a report shows estimates, observers and the shared pond', (
    tester,
    db,
  ) async {
    final id = await pulled(tester, db, full());
    go(tester, '/reports/$id');
    await tester.pumpAndSettle();
    expect(find.text('Du 13/03/2026 au 20/03/2026'), findsOneWidget);
    expect(find.text('Rakoto 4 · inconnu 2'), findsOneWidget);
    expect(find.textContaining('29,7 kg', findRichText: true), findsOneWidget);
    expect(find.textContaining('estimé', findRichText: true), findsWidgets);
    expect(find.textContaining('bassin partagé'), findsOneWidget);
    expect(find.text('Aucun relevé'), findsOneWidget);
    expect(find.textContaining('Fuite côté sud'), findsOneWidget);
    expect(
      find.text("Stock d'aliment : à partir de la gestion des stocks"),
      findsOneWidget,
    );
  });

  appTest('an empty report shows each section\'s empty line', (
    tester,
    db,
  ) async {
    final id = await pulled(tester, db, empty());
    go(tester, '/reports/$id');
    await tester.pumpAndSettle();
    for (final heading in const [
      'Résumé',
      'Alertes',
      'Santé',
      'Eau',
      'Croissance',
      'Aliment',
      'À venir',
      'Observations et photos',
    ]) {
      final inReport = find.descendant(
        of: find.byType(ReportScreen),
        matching: find.text(heading),
      );
      await tester.scrollUntilVisible(
        inReport,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ReportScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(inReport, findsOneWidget, reason: heading);
    }
    expect(find.text('Rien à signaler'), findsWidgets);
    expect(find.text('NaN'), findsNothing);
  });

  appTest('a report from a newer app asks for an update', (tester, db) async {
    final id = await pulled(tester, db, empty(), raw: '{"format":2}');
    go(tester, '/reports/$id');
    await tester.pumpAndSettle();
    expect(
      find.text("Mettez l'application à jour pour lire ce rapport."),
      findsOneWidget,
    );
  });

  appTest('a full report fits a 360 × 640 screen', (tester, db) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final id = await pulled(tester, db, full());
    go(tester, '/reports/$id');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  appTest(
    'a worker session has no reports',
    (tester, db) async {
      go(tester, '/reports');
      await tester.pumpAndSettle();
      expect(find.text('Rapports'), findsNothing);
    },
    role: MemberRole.worker,
    isAdmin: false,
  );

  appTest('summary typed just before leaving the draft is kept', (
    tester,
    db,
  ) async {
    final s = (await SetupRepository(db).currentSession())!;
    final visits = VisitRepository(db, s);
    final v = await visits.start();
    await visits.end(v);
    go(tester, '/reports/draft/$v');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Résumé'),
      'Digue sud à reprendre',
    );
    await tester.pump(const Duration(milliseconds: 100));
    go(tester, '/reports');
    await tester.pumpAndSettle();
    expect((await visits.get(v)).summary, 'Digue sud à reprendre');
  });

  appTest('the draft card leads to the draft', (tester, db) async {
    final s = (await SetupRepository(db).currentSession())!;
    final visits = VisitRepository(db, s);
    await visits.end(await visits.start());
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Rapports'));
    await tapAndSettle(tester, find.text('Brouillon — à publier'));
    expect(find.text('Publier'), findsOneWidget);
  });

  final shared = <File>[];
  appTest(
    'Partager writes the PDF and opens the share sheet',
    (tester, db) async {
      shared.clear();
      final id = await pulled(tester, db, full());
      go(tester, '/reports/$id');
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Partager'));
        // Fonts and the PDF are built off the test clock.
        for (var i = 0; i < 50 && shared.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pumpAndSettle();
      final file = shared.single;
      expect(file.path, endsWith('rapport-Ambohidratrimo-2026-03-20.pdf'));
      expect(String.fromCharCodes(file.readAsBytesSync().take(4)), '%PDF');
    },
    overrides: [
      reportSharerProvider.overrideWithValue((file) async => shared.add(file)),
      backupDirProvider.overrideWithValue(
        () async => Directory.systemTemp.createTemp('dobo-share'),
      ),
    ],
  );
}
