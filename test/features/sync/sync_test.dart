import 'package:dobo/db/database.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/sync/providers.dart';
import 'package:dobo/sync/sync_controller.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../../sync/fake_auth_gateway.dart';
import '../../sync/fake_sync_api.dart';

/// A phone linked to an account, with a server that answers.
Future<void> link(AppDatabase db) => db
    .into(db.localMeta)
    .insert(LocalMetaCompanion.insert(key: 'linked', value: '1'));

Future<void> addLogs(
  WidgetTester tester,
  AppDatabase db,
  List<String> ids,
) async {
  final s = (await appContainer(tester).read(sessionProvider.future))!;
  for (final id in ids) {
    await db
        .into(db.dailyLogs)
        .insert(
          DailyLogsCompanion.insert(
            id: Value(id),
            associationId: s.associationId,
            enteredBy: s.userId,
            deviceId: s.deviceId,
            recordedAt: DateTime.utc(2026, 3, 1, 9),
            pondId: 'p1',
            feedGivenG: 600,
          ),
        );
  }
  await tester.pumpAndSettle();
}

void main() {
  late FakeSyncApi server;

  setUp(() => server = FakeSyncApi());

  // Read lazily: tests are declared before setUp makes the server.
  List<Override> online() => [
    syncApiProvider.overrideWith((ref) => server),
    authGatewayProvider.overrideWith(
      (ref) => FakeAuthGateway()..signedIn = true,
    ),
  ];

  appTest('Synchroniser sends what is pending and clears the badge', (
    tester,
    db,
  ) async {
    await link(db);
    await tester.pumpAndSettle();
    await addLogs(tester, db, ['l1', 'l2']);
    expect(
      find.descendant(
        of: find.byKey(const Key('syncBadge')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Synchronisation'));
    await tapAndSettle(tester, find.text('Synchroniser'));

    expect(server.rows['daily_logs'], hasLength(2));
    expect(find.text('2'), findsNothing);
  }, overrides: online());

  appTest('a refused row is listed with the reason and can be retried', (
    tester,
    db,
  ) async {
    await link(db);
    await tester.pumpAndSettle();
    server.refuse('daily_logs', '42501');
    await addLogs(tester, db, ['l1']);
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Synchronisation'));
    await tapAndSettle(tester, find.text('Synchroniser'));

    expect(
      find.text('Votre rôle ne permet pas cet enregistrement'),
      findsOneWidget,
    );
    // Once the server accepts it (say, a member signs in), retrying sends it.
    server.accept('daily_logs');
    await tapAndSettle(tester, find.text('Réessayer les refusés'));
    final log = await db.select(db.dailyLogs).getSingle();
    expect(log.syncState, SyncState.synced);
    expect(
      find.text('Votre rôle ne permet pas cet enregistrement'),
      findsNothing,
    );
  }, overrides: online());

  appTest('an M3 phone is offered to create the association\'s account', (
    tester,
    db,
  ) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Synchronisation'));
    expect(find.text('Créer le compte de l\'association'), findsOneWidget);
  }, overrides: online());

  test('two syncs asked for at once run once', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await SetupRepository(db).completeSetup(siteName: 'Ambohidratrimo');
    await link(db);
    final c = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db), ...online()],
    );
    addTearDown(c.dispose);
    // Riverpod pauses providers nobody listens to.
    c.listen(sessionProvider, (_, _) {});
    await c.read(sessionProvider.future);
    final sync = c.read(syncControllerProvider.notifier);
    final first = sync.syncNow();
    final second = sync.syncNow();
    expect(identical(first, second), true);
    await Future.wait([first, second]);
    // One run: the site pushed, then one pull per synced table.
    expect(server.calls, 1 + 16);
    expect(c.read(syncControllerProvider).state, SyncRunState.idle);
  });
}
