import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/errors.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/features/alerts/alert_providers.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/daily_log/duplicate_logs_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';

class _StaleLogs extends DailyLogRepository {
  _StaleLogs(super.db, super.session);

  @override
  Future<String> keepOnly(String keepId, List<String> discardIds) async =>
      throw StaleEventException(keepId);
}

void main() {
  final now = DateTime.utc(2026, 3, 20, 6);
  final clock = clockProvider.overrideWithValue(() => now);
  final day = DateTime(2026, 3, 19);

  /// An empty pond E1 with two current logs for 19/03: this phone's
  /// (4 kg) and another phone's (5 kg).
  Future<void> twoLogs(AppDatabase db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final e1 = await PondRepository(db, session).create(pondInput('E1'));
    await DailyLogRepository(
      db,
      session,
    ).save(DailyLogInput(pondId: e1, date: day, feedGivenG: 4000));
    await db
        .into(db.dailyLogs)
        .insert(
          DailyLogsCompanion.insert(
            associationId: session.associationId,
            enteredBy: 'other-user',
            deviceId: 'other-phone',
            createdAtDevice: Value(now.add(const Duration(minutes: 1))),
            recordedAt: farmDateToUtc(day),
            pondId: e1,
            feedGivenG: 5000,
            deaths: const Value(3),
          ),
        );
  }

  Future<void> openFromAlerts(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Alertes'),
      ),
    );
    await tapAndSettle(tester, find.textContaining('Deux journaux'));
  }

  appTest('two logs shown side by side', (tester, db) async {
    await twoLogs(db);
    await openFromAlerts(tester);
    expect(find.byType(DuplicateLogsScreen), findsOneWidget);
    expect(find.text('Garder celui-ci'), findsNWidgets(2));
    expect(find.textContaining('4 kg'), findsOneWidget);
    expect(find.textContaining('5 kg'), findsOneWidget);
  }, overrides: [clock]);

  appTest('Garder removes the duplicate alert', (tester, db) async {
    await twoLogs(db);
    await openFromAlerts(tester);
    await tapAndSettle(tester, find.text('Garder celui-ci').first);
    expect(find.textContaining('Résolu'), findsOneWidget);
    final alerts = appContainer(tester).read(alertsProvider).requireValue;
    expect(alerts.where((a) => a.kind == AlertKind.duplicateDailyLog), isEmpty);
    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.text('Aucune alerte, rien à faire'), findsOneWidget);
  }, overrides: [clock]);

  appTest(
    'stale keep shows the stale-record message',
    (tester, db) async {
      await twoLogs(db);
      await openFromAlerts(tester);
      await tapAndSettle(tester, find.text('Garder celui-ci').first);
      expect(
        find.text('Ce journal a déjà été changé sur un autre téléphone'),
        findsOneWidget,
      );
      expect(find.text('Garder celui-ci'), findsNWidgets(2));
    },
    overrides: [
      clock,
      dailyLogRepositoryProvider.overrideWith(
        (ref) => _StaleLogs(
          ref.watch(databaseProvider),
          ref.watch(sessionProvider).requireValue!,
        ),
      ),
    ],
  );
}
