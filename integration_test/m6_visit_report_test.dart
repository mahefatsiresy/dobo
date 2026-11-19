import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/app.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/photos/photo_capture.dart';
import 'package:dobo/features/reports/share_report.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers.dart';

/// A 1×1 PNG standing in for a camera shot.
final _shot = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0xF0,
  0x1F,
  0x00,
  0x05,
  0x00,
  0x01,
  0xFF,
  0x89,
  0x99,
  0x3D,
  0x1D,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _Camera implements PhotoCapture {
  @override
  Future<Uint8List?> takeCompressed() async => _shot;

  @override
  Future<Uint8List?> recoverLost() async => null;
}

/// M6 milestone walk-through on a device, against the real database. Run it
/// in airplane mode on a freshly cleared app:
///   adb shell pm clear mg.dobo.dobo
///   flutter test integration_test/m6_visit_report_test.dart -d DEVICE
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  final shared = <File>[];

  testWidgets('a visit becomes a report with who saw what, a photo and a PDF', (
    tester,
  ) async {
    final overrides = [
      photoCaptureProvider.overrideWithValue(_Camera()),
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

    // Setup: E1 with L1 stocked 15 days ago; the worker's account is linked
    // to Rakoto; Hery's paper sheet is transcribed.
    await enterAndSettle(tester, field('Nom du site'), 'Ambohidratrimo');
    await tapAndSettle(tester, find.text('Commencer'));
    await tapAndSettle(tester, find.text('Ajouter un étang'));
    await enterAndSettle(tester, field('Code'), 'E1');
    await enterAndSettle(tester, field('Longueur'), '25');
    await enterAndSettle(tester, field('Largeur'), '20');
    await tapAndSettle(tester, find.text('Enregistrer'));
    final session = container.read(sessionProvider).requireValue!;
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
    Future<void> person(String id, String name) => db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            id: Value(id),
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            name: name,
          ),
        );
    await person('p-rakoto', 'Rakoto');
    await person('p-hery', 'Hery');
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: const Value('m-worker'),
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: 'worker-phone',
            name: 'rakoto',
            personId: const Value('p-rakoto'),
            role: MemberRole.worker,
            locale: 'mg',
            syncState: const Value(SyncState.synced),
          ),
        );
    // Logged on the worker's own phone, synced here.
    await db
        .into(db.dailyLogs)
        .insert(
          DailyLogsCompanion.insert(
            associationId: session.associationId,
            enteredBy: 'm-worker',
            deviceId: 'worker-phone',
            recordedAt: farmDateToUtc(daysAgo(1)),
            pondId: e1,
            feedGivenG: 1000,
            deaths: const Value(4),
            syncState: const Value(SyncState.synced),
          ),
        );
    await container
        .read(dailyLogRepositoryProvider)
        .save(
          DailyLogInput(
            pondId: e1,
            date: daysAgo(2),
            feedGivenG: 1000,
            deaths: 2,
            observedBy: 'p-hery',
          ),
        );
    await tester.pumpAndSettle();

    // 1. A visit: low oxygen, a sample, an observation with a photo; the
    // summary is written in the draft.
    await tapAndSettle(tester, tab('Visite'));
    await tapAndSettle(tester, find.text('Commencer la visite'));
    await tapAndSettle(tester, find.byKey(const ValueKey('water-E1')));
    await enterAndSettle(tester, field('Oxygène dissous'), '2');
    await tapAndSettle(tester, find.text('Enregistrer'));
    await tapAndSettle(tester, find.byKey(const ValueKey('sample-L1-E1')));
    await enterAndSettle(tester, field('Poissons pesés'), '40');
    await enterAndSettle(tester, field('Poids total'), '1,2');
    await tapAndSettle(tester, find.text('Enregistrer'));
    await tapAndSettle(tester, find.text('Ajouter une observation'));
    await enterAndSettle(
      tester,
      find.widgetWithText(TextField, 'Observation'),
      'Fuite à la digue sud',
    );
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Enregistrer'),
      ),
    );
    await tapAndSettle(tester, find.text('Ajouter une photo'));
    expect(await db.select(db.photos).get(), hasLength(1));

    // 2. Ending opens the draft: who saw the deaths, the alert, estimates.
    await tapAndSettle(tester, find.text('Terminer la visite'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Terminer la visite'),
      ),
    );
    expect(find.text('Rapport de visite'), findsOneWidget);
    await enterAndSettle(
      tester,
      find.widgetWithText(TextField, 'Résumé'),
      'Oxygène bas le matin, digue à reprendre.',
    );
    for (final text in [
      'Rakoto 4 · Hery 2',
      'estimé',
      'Fuite à la digue sud',
    ]) {
      await tester.scrollUntilVisible(
        find.textContaining(text, findRichText: true).first,
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    expect(find.textContaining('Oxygène dissous'), findsWidgets);

    // 3. Publish: listed, not bold (my own).
    await tapAndSettle(tester, find.text('Publier'));
    final report = await db.select(db.visitReports).getSingle();
    final content = ReportContent.decode(report.content);
    expect(content.health.single.byObserver.map((o) => o.name), [
      'Rakoto',
      'Hery',
    ]);
    expect(
      content.observations.where((o) => o.photoKeys.isNotEmpty),
      hasLength(1),
    );

    // 4. Partager builds the PDF (the share sheet is stubbed).
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Partager'));
      for (var i = 0; i < 100 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pumpAndSettle();
    expect(
      String.fromCharCodes(shared.single.readAsBytesSync().take(4)),
      '%PDF',
    );

    await tapAndSettle(tester, tab('Rapports'));
    expect(find.text('Brouillon — à publier'), findsNothing);
    expect(find.textContaining('Du '), findsOneWidget);

    // 5. Reopen the app on the same database: the report and photo remain.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const DoboApp()),
    );
    await tester.pumpAndSettle();
    await tapAndSettle(tester, tab('Rapports'));
    expect(find.textContaining('Du '), findsOneWidget);
    final again = ProviderScope.containerOf(
      tester.element(find.byType(DoboApp)),
    ).read(databaseProvider);
    expect(await again.select(again.visitReports).get(), hasLength(1));
    expect(await again.select(again.photos).get(), hasLength(1));
  });
}
