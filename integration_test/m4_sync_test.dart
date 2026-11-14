import 'dart:convert';
import 'dart:io';

import 'package:dobo/app.dart';
import 'package:dobo/db/database_provider.dart';
import 'package:dobo/db/ids.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/features/sync/backup_actions.dart';
import 'package:dobo/sync/server_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/helpers.dart';

/// M4 milestone walk-through on a device, against the local Supabase stack
/// (`supabase start`; `env/local.json` points the emulator at the host).
/// Three parts, each on a freshly cleared app, chosen with M4_PART; M4_RUN
/// makes the accounts unique:
///
///   founder  founds the association through the found-association
///            function (as the web console does), signs in on the phone,
///            then adds a pond, the worker's account and a stocking;
///            records offline; syncs when the network is back.
///            It prints M4:OFFLINE_PLEASE and M4:ONLINE_PLEASE and waits
///            until the host has cut or restored the emulator's network
///            (adb shell svc wifi disable|enable; svc data disable|enable),
///            then exports a backup to the app's external files folder.
///   worker   signs in as the worker on a wiped phone, logs E1, syncs.
///   restore  imports the founder's backup (M4_BACKUP, pushed to the app's
///            external files folder) on a wiped phone with no network.
///
///   flutter test integration_test/m4_sync_test.dart -d DEVICE \
///     --dart-define-from-file=env/local.json \
///     --dart-define=M4_PART=founder --dart-define=M4_RUN=123 \
///     --dart-define=FOUNDING_CODE=dobo-local-founding
///
/// The local founding code is spent once used. Before the founder part,
/// make it usable again on the host:
///   psql "$DB_URL" -c 'truncate founding_codes_spent'
/// with DB_URL from `supabase status -o env`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const part = String.fromEnvironment('M4_PART');
  const run = String.fromEnvironment('M4_RUN');
  const backupName = String.fromEnvironment('M4_BACKUP');
  const foundingCode = String.fromEnvironment('FOUNDING_CODE');

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  /// Pumps until [finder] shows: network work runs in real time.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) fail('Timed out waiting for $finder');
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
  }

  Future<bool> serverReachable() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final req = await client.getUrl(Uri.parse('$supabaseUrl/auth/v1/health'));
      await (await req.close()).drain<void>();
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Founds the association as the web console does (SPEC F16).
  Future<void> foundAssociation(String email) async {
    final memberId = newId();
    final client = HttpClient();
    try {
      final req = await client.postUrl(
        Uri.parse('$supabaseUrl/functions/v1/found-association'),
      );
      req.headers
        ..contentType = ContentType.json
        ..set('apikey', supabaseAnonKey)
        ..set('Authorization', 'Bearer $supabaseAnonKey');
      req.write(
        jsonEncode({
          'code': foundingCode,
          'email': email,
          'password': 'motdepasse1',
          'founderName': 'Soa',
          'associationName': 'Famille',
          'groupName': 'Branche 1',
          'siteName': 'Ambohidratrimo',
          'associationId': newId(),
          'groupId': newId(),
          'siteId': newId(),
          'memberId': memberId,
          'personId': accountPersonId(memberId),
          'deviceId': newId(),
        }),
      );
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      expect(res.statusCode, 200, reason: body);
    } finally {
      client.close();
    }
  }

  Future<void> waitForNetwork({required bool up}) async {
    for (var i = 0; i < 150; i++) {
      if (await serverReachable() == up) return;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    fail('The network never went ${up ? 'up' : 'down'}');
  }

  Future<void> start(WidgetTester tester, List<Override> overrides) async {
    expect(serverConfigured, true, reason: 'run with env/local.json');
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const DoboApp()),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(DoboApp)));

  Future<int> pending(WidgetTester tester) =>
      container(tester).read(accountRepositoryProvider)!.pendingCount();

  Future<void> syncFromScreen(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Synchronisation'));
    await tapAndSettle(tester, find.text('Synchroniser'));
    await pumpUntil(tester, find.text('Synchroniser'));
  }

  testWidgets('M4 $part', (tester) async {
    switch (part) {
      case 'founder':
        final dir = await getExternalStorageDirectory();
        await start(tester, [
          backupDirProvider.overrideWithValue(() async => dir!),
          backupSharerProvider.overrideWithValue((_) async {}),
        ]);

        // 1. Online: the association, a pond, the worker's account, a
        // stocking; then sync.
        expect(foundingCode, isNotEmpty, reason: 'pass FOUNDING_CODE');
        await foundAssociation('founder$run@test.mg');
        await tapAndSettle(tester, find.byKey(const Key('welcomeMember')));
        await enterAndSettle(
          tester,
          find.byKey(const Key('login')),
          'founder$run@test.mg',
        );
        await enterAndSettle(
          tester,
          find.byKey(const Key('secret')),
          'motdepasse1',
        );
        await tapAndSettle(tester, find.byKey(const Key('signIn')));
        await pumpUntil(tester, find.text('Ajouter un étang'));

        await tapAndSettle(tester, find.text('Ajouter un étang'));
        await enterAndSettle(tester, field('Code'), 'E1');
        await enterAndSettle(tester, field('Longueur'), '25');
        await enterAndSettle(tester, field('Largeur'), '20');
        await tapAndSettle(tester, find.text('Vide'));
        await tapAndSettle(tester, find.textContaining('Prêt').last);
        await tapAndSettle(tester, find.text('Enregistrer'));

        await tapAndSettle(tester, find.text('Plus'));
        await tapAndSettle(tester, find.text('Administration'));
        await tapAndSettle(tester, find.text('Membres'));
        await tapAndSettle(tester, find.text('Ajouter'));
        await enterAndSettle(
          tester,
          find.byKey(const Key('memberName')),
          'Rakoto',
        );
        await tapAndSettle(tester, find.text('Ouvrier'));
        await enterAndSettle(
          tester,
          find.byKey(const Key('login')),
          'rakoto$run',
        );
        await enterAndSettle(tester, find.byKey(const Key('secret')), '123456');
        await tapAndSettle(tester, find.byKey(const Key('saveMember')));
        await pumpUntil(tester, find.text('Rakoto'));

        await tapAndSettle(tester, find.text('Étangs'));
        if (find.text('Ajouter un étang').evaluate().isEmpty) {
          await tapAndSettle(tester, find.text('Étangs'));
        }
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

        await syncFromScreen(tester);
        expect(await pending(tester), 0);

        // 2. No network: a day logged in worker mode and a water reading.
        // ignore: avoid_print
        print('M4:OFFLINE_PLEASE');
        await waitForNetwork(up: false);
        await tapAndSettle(tester, find.text('Plus'));
        await tapAndSettle(tester, find.text('Mode ouvrier'));
        await tapAndSettle(tester, find.text('E1'));
        await enterAndSettle(tester, field('Sakafo nomena'), '0,6');
        await tapAndSettle(tester, find.text('Tehirizo'));
        await tapAndSettle(tester, find.byTooltip('Hiala'));
        await tapAndSettle(tester, find.text('Étangs'));
        if (find.text('Ajouter un étang').evaluate().isEmpty) {
          await tapAndSettle(tester, find.text('Étangs'));
        }
        await tapAndSettle(tester, find.text('E1'));
        await tapAndSettle(tester, find.text("Relevé d'eau"));
        await enterAndSettle(tester, field('pH'), '7,2');
        await enterAndSettle(tester, field('Oxygène dissous'), '4,5');
        await tapAndSettle(tester, find.text('Enregistrer'));
        expect(await pending(tester), 2);
        expect(
          find.descendant(
            of: find.byKey(const Key('syncBadge')),
            matching: find.text('2'),
          ),
          findsWidgets,
        );
        await syncFromScreen(tester);
        expect(find.textContaining('Pas de connexion'), findsOneWidget);
        expect(await pending(tester), 2);

        // 3. The network is back: one tap sends both.
        // ignore: avoid_print
        print('M4:ONLINE_PLEASE');
        await waitForNetwork(up: true);
        await tapAndSettle(tester, find.text('Synchroniser'));
        await pumpUntil(tester, find.text('En attente d\'envoi : 0'));
        expect(await pending(tester), 0);

        final session = container(tester).read(sessionProvider).value!;
        // ignore: avoid_print
        print('M4:FOUNDER=${session.userId}');

        // Backup, for the restore part.
        await tapAndSettle(tester, find.text('Exporter une sauvegarde'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        final files = dir!
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sqlite'))
            .toList();
        expect(files, isNotEmpty);
        // ignore: avoid_print
        print('M4:BACKUP=${files.single.uri.pathSegments.last}');

      case 'worker':
        await start(tester, const []);
        await tapAndSettle(tester, find.byKey(const Key('welcomeWorker')));
        await enterAndSettle(
          tester,
          find.byKey(const Key('login')),
          'rakoto$run',
        );
        await enterAndSettle(tester, find.byKey(const Key('secret')), '123456');
        await tapAndSettle(tester, find.byKey(const Key('signIn')));
        // The first sync brings the pond and today's log: E1 with a tick.
        await pumpUntil(tester, find.byIcon(Icons.task_alt));
        expect(find.text('E1'), findsOneWidget);
        expect(
          Localizations.localeOf(tester.element(find.text('E1'))),
          const Locale('mg'),
        );
        expect(find.byTooltip('Hiala'), findsNothing);

        await tapAndSettle(tester, find.text('E1'));
        await enterAndSettle(tester, field('Sakafo nomena'), '0,7');
        await tapAndSettle(tester, find.text('Tehirizo'));
        await tapAndSettle(tester, find.byKey(const Key('workerSync')));
        for (var i = 0; i < 60 && await pending(tester) > 0; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(await pending(tester), 0);
        final session = container(tester).read(sessionProvider).value!;
        // ignore: avoid_print
        print('M4:WORKER=${session.userId}');

      case 'restore':
        final dir = await getExternalStorageDirectory();
        await start(tester, [
          backupPickerProvider.overrideWithValue(
            () async => File('${dir!.path}/$backupName'),
          ),
        ]);
        await tapAndSettle(tester, find.byKey(const Key('welcomeImport')));
        await pumpUntil(tester, find.text('E1'));
        final db = container(tester).read(databaseProvider);
        expect(await db.select(db.dailyLogs).get(), isNotEmpty);
        expect(await db.select(db.waterReadings).get(), hasLength(1));

      default:
        fail('Set M4_PART to founder, worker or restore');
    }
  });
}
