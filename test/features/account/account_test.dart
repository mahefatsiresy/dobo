import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/daily_log/worker_home_screen.dart';
import 'package:dobo/router.dart';
import 'package:dobo/sync/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../../sync/fake_auth_gateway.dart';
import '../../sync/fake_sync_api.dart';

void main() {
  appTest(
    'a worker signs in and lands on the locked worker home in Malagasy',
    (tester, db) async {
      await tapAndSettle(tester, find.byKey(const Key('welcomeWorker')));
      await enterAndSettle(tester, find.byKey(const Key('login')), 'rakoto');
      await enterAndSettle(tester, find.byKey(const Key('secret')), '123456');
      await tapAndSettle(tester, find.byKey(const Key('signIn')));

      expect(find.byType(WorkerHomeScreen), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsNothing);
      expect(
        Localizations.localeOf(tester.element(find.byType(WorkerHomeScreen))),
        const Locale('mg'),
      );
      appContainer(tester).read(routerProvider).go('/ponds');
      await tester.pumpAndSettle();
      expect(find.byType(WorkerHomeScreen), findsOneWidget);
    },
    setUp: false,
    overrides: [
      authGatewayProvider.overrideWithValue(
        FakeAuthGateway(
          member: remoteMember(id: 'w1', role: MemberRole.worker, locale: 'mg'),
        ),
      ),
    ],
  );

  appTest('signing out names the unsent records and keeps them', (
    tester,
    db,
  ) async {
    final session = (await appContainer(tester).read(sessionProvider.future))!;
    for (final id in ['l1', 'l2']) {
      await db
          .into(db.dailyLogs)
          .insert(
            DailyLogsCompanion.insert(
              id: Value(id),
              associationId: session.associationId,
              enteredBy: session.userId,
              deviceId: session.deviceId,
              recordedAt: DateTime.utc(2026, 3, 1, 9),
              pondId: 'p1',
              feedGivenG: 600,
            ),
          );
    }
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Compte'));
    await tapAndSettle(tester, find.byKey(const Key('signOut')));
    expect(find.textContaining('3 enregistrements'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('confirmSignOut')));

    expect(find.byKey(const Key('welcomeWorker')), findsOneWidget);
    expect(await db.select(db.dailyLogs).get(), hasLength(2));
    expect(await db.select(db.sites).get(), hasLength(1));
  }, overrides: [authGatewayProvider.overrideWithValue(FakeAuthGateway())]);

  appTest(
    'with no network, signing in says a connection is needed',
    (tester, db) async {
      await tapAndSettle(tester, find.byKey(const Key('welcomeMember')));
      await enterAndSettle(tester, find.byKey(const Key('login')), 'soa@a.mg');
      await enterAndSettle(
        tester,
        find.byKey(const Key('secret')),
        'motdepasse',
      );
      await tapAndSettle(tester, find.byKey(const Key('signIn')));
      expect(find.text('Connexion nécessaire'), findsOneWidget);
    },
    setUp: false,
    overrides: [
      authGatewayProvider.overrideWithValue(FakeAuthGateway()..offline = true),
    ],
  );

  appTest('a build with no server opens the offline setup', (tester, db) async {
    expect(find.text('Nom du site'), findsOneWidget);
  }, setUp: false);

  appTest(
    'the welcome screen switches to Malagasy',
    (tester, db) async {
      await tapAndSettle(tester, find.text('MG'));
      expect(find.text('Mpiasa aho'), findsOneWidget);
    },
    setUp: false,
    overrides: [authGatewayProvider.overrideWithValue(FakeAuthGateway())],
  );

  appTest(
    'a worker whose session ended signs back in from the worker home',
    (tester, db) async {
      await db
          .into(db.localMeta)
          .insert(LocalMetaCompanion.insert(key: 'linked', value: '1'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkerHomeScreen), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const Key('workerRelogin')));
      expect(find.byKey(const Key('secret')), findsOneWidget);
      expect(find.text('Kaody PIN (isa 6)'), findsOneWidget);
    },
    role: MemberRole.worker,
    isAdmin: false,
    overrides: [
      authGatewayProvider.overrideWithValue(FakeAuthGateway()),
      syncApiProvider.overrideWithValue(FakeSyncApi()),
    ],
  );

  group('admin takeover', () {
    late FakeAuthGateway auth;
    setUp(() => auth = FakeAuthGateway());

    Future<void> linkedWorker(WidgetTester tester, AppDatabase db) async {
      final s = (await appContainer(tester).read(sessionProvider.future))!;
      auth.member = remoteMember(
        id: 'm1',
        associationId: s.associationId,
        siteId: s.siteId,
        isAdmin: true,
      );
      auth.signedIn = true;
      await db
          .into(db.localMeta)
          .insert(LocalMetaCompanion.insert(key: 'linked', value: '1'));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('workerTakeover')));
      await tester.pumpAndSettle();
      expect(find.text('Haverina ity telefaonina ity'), findsOneWidget);
      await enterAndSettle(tester, find.byKey(const Key('login')), 'soa@b.mg');
      await enterAndSettle(
        tester,
        find.byKey(const Key('secret')),
        'motdepasse',
      );
    }

    appTest(
      'an admin takes a worker\'s phone back from the worker home',
      (tester, db) async {
        await linkedWorker(tester, db);
        await tapAndSettle(tester, find.byKey(const Key('signIn')));
        expect(find.byType(WorkerHomeScreen), findsNothing);
        final s = (await appContainer(tester).read(sessionProvider.future))!;
        expect((s.userId, s.isAdmin), ('m1', true));
      },
      role: MemberRole.worker,
      isAdmin: false,
      overrides: [
        authGatewayProvider.overrideWith((ref) => auth),
        syncApiProvider.overrideWithValue(FakeSyncApi()),
      ],
    );

    appTest(
      'unsent worker records keep the phone with the worker',
      (tester, db) async {
        final s = (await appContainer(tester).read(sessionProvider.future))!;
        await db
            .into(db.dailyLogs)
            .insert(
              DailyLogsCompanion.insert(
                associationId: s.associationId,
                enteredBy: s.userId,
                deviceId: s.deviceId,
                recordedAt: DateTime.utc(2026, 3, 1, 9),
                pondId: 'p1',
                feedGivenG: 600,
              ),
            );
        await linkedWorker(tester, db);
        await tapAndSettle(tester, find.byKey(const Key('signIn')));
        expect(find.textContaining('mbola tsy lasa'), findsOneWidget);
        final after = (await appContainer(tester)
            .read(sessionProvider.future))!;
        expect(after.isWorker, true);
        expect(auth.lastEmail, isNull);
      },
      role: MemberRole.worker,
      isAdmin: false,
      overrides: [
        authGatewayProvider.overrideWith((ref) => auth),
        syncApiProvider.overrideWithValue(FakeSyncApi()..failAfterCalls(0)),
      ],
    );
  });
}
