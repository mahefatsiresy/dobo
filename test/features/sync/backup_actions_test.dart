import 'dart:io';

import 'package:dobo/db/backup.dart';
import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/features/ponds/ponds_screen.dart';
import 'package:dobo/features/sync/backup_actions.dart';
import 'package:dobo/sync/providers.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../../sync/fake_auth_gateway.dart';

void main() {
  late Directory dir;
  late File backup;
  File? shared;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = await Directory.systemTemp.createTemp('dobo-backup-ui');
    final old = AppDatabase(NativeDatabase.memory());
    await SetupRepository(old).completeSetup(siteName: 'Ambohidratrimo');
    backup = await exportBackup(old, dir);
    await old.close();
  });
  tearDownAll(() => dir.delete(recursive: true));

  /// Taps [finder] and lets the file work finish. The database lives in
  /// the test's fake clock and the files in real time: alternate the two.
  Future<void> tapWithFiles(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  appTest(
    'a new phone with no network imports a backup and opens on the ponds',
    (tester, db) async {
      await tapWithFiles(tester, find.byKey(const Key('welcomeImport')));
      expect(find.byType(PondsScreen), findsOneWidget);
      expect(await db.select(db.sites).get(), hasLength(1));
    },
    setUp: false,
    overrides: [
      authGatewayProvider.overrideWithValue(FakeAuthGateway()..offline = true),
      backupPickerProvider.overrideWithValue(() async => backup),
    ],
  );

  appTest(
    'export shares a file of the phone\'s database',
    (tester, db) async {
      await tapAndSettle(tester, find.text('Plus'));
      await tapAndSettle(tester, find.text('Synchronisation'));
      await tapAndSettle(tester, find.text('Sauvegarde'));
      await tapWithFiles(tester, find.text('Exporter une sauvegarde'));
      expect(shared, isNotNull);
      expect(shared!.lengthSync(), greaterThan(0));
    },
    overrides: [
      backupDirProvider.overrideWithValue(() async => dir),
      backupSharerProvider.overrideWithValue((file) async => shared = file),
    ],
  );
}
