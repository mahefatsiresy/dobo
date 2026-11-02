import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/db/photo_files.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/providers.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/photos/photo_capture.dart';
import 'package:dobo/features/photos/photo_strip.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:dobo/sync/providers.dart';
import 'package:dobo/sync/photo_store.dart';

import '../../sync/fake_photo_store.dart';

import '../../db/repo_fixtures.dart';
import '../../helpers.dart';

/// A 1×1 PNG: decodable by the test image codec.
final tinyImage = Uint8List.fromList([
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

class FakeCapture implements PhotoCapture {
  FakeCapture(this.next);

  Future<Uint8List?> Function() next;

  @override
  Future<Uint8List?> takeCompressed() => next();
}

/// Photo files in fresh temporary folders.
Override tempPhotoFiles() {
  final docs = Directory.systemTemp.createTempSync('dobo-docs');
  final cache = Directory.systemTemp.createTempSync('dobo-cache');
  return photoFilesProvider.overrideWithValue(
    PhotoFiles(docs: () async => docs, cache: () async => cache),
  );
}

void main() {
  final capture = FakeCapture(() async => tinyImage);

  Future<void> openDraft(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Visite'));
    await tapAndSettle(tester, find.text('Démarrer une visite'));
    await tapAndSettle(tester, find.text('Terminer la visite'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Terminer la visite'),
      ),
    );
  }

  appTest(
    'a photo added to the draft shows and goes into the report',
    (tester, db) async {
      capture.next = () async => tinyImage;
      await openDraft(tester);
      await tapAndSettle(tester, find.text('Ajouter une photo'));
      final photo = await db.select(db.photos).getSingle();
      expect(photo.ownerKind, PhotoOwner.visit);
      expect(
        find.descendant(
          of: find.byType(PhotoStrip),
          matching: find.byKey(ValueKey('photo-${photo.photoKey}')),
        ),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.text('Publier'));
      final r = await db.select(db.visitReports).getSingle();
      expect(ReportContent.decode(r.content).visitPhotoKeys, [photo.photoKey]);
    },
    overrides: [
      photoCaptureProvider.overrideWithValue(capture),
      tempPhotoFiles(),
    ],
  );

  appTest(
    'a cancelled capture saves nothing',
    (tester, db) async {
      capture.next = () async => null;
      await openDraft(tester);
      await tapAndSettle(tester, find.text('Ajouter une photo'));
      expect(await db.select(db.photos).get(), isEmpty);
    },
    overrides: [
      photoCaptureProvider.overrideWithValue(capture),
      tempPhotoFiles(),
    ],
  );

  appTest(
    'marking a photo to send writes a new version',
    (tester, db) async {
      capture.next = () async => tinyImage;
      await openDraft(tester);
      await tapAndSettle(tester, find.text('Ajouter une photo'));
      final key = (await db.select(db.photos).getSingle()).photoKey;
      await tapAndSettle(tester, find.byKey(ValueKey('photo-$key')));
      await tapAndSettle(tester, find.text('Envoyer au serveur'));
      final rows = await db.select(db.photos).get();
      expect(rows, hasLength(2));
      expect(rows.last.upload, isTrue);
    },
    overrides: [
      photoCaptureProvider.overrideWithValue(capture),
      tempPhotoFiles(),
    ],
  );

  appTest(
    'a failed capture shows a message and saves nothing',
    (tester, db) async {
      capture.next = () async => throw Exception('camera busy');
      await openDraft(tester);
      await tapAndSettle(tester, find.text('Ajouter une photo'));
      expect(
        find.text(
          "La photo n'a pas pu être prise. L'enregistrement se fait sans elle.",
        ),
        findsOneWidget,
      );
      expect(await db.select(db.photos).get(), isEmpty);
    },
    overrides: [photoCaptureProvider.overrideWithValue(capture), tempPhotoFiles()],
  );

  appTest(
    'a health event gets its photo from the pond page, after it is saved',
    (tester, db) async {
      capture.next = () async => tinyImage;
      final s = (await SetupRepository(db).currentSession())!;
      final e1 = await PondRepository(db, s).create(pondInput('E1'));
      await tester.pumpAndSettle();
      appContainer(tester).read(routerProvider).go('/ponds/$e1/problem');
      await tester.pumpAndSettle();
      // The form never opens the camera: nothing unsaved can be lost.
      expect(find.text('Ajouter une photo'), findsNothing);
      await tapAndSettle(tester, find.text('Se frotte'));
      await tapAndSettle(tester, find.text('Enregistrer'));
      final event = await db.select(db.healthEvents).getSingle();

      appContainer(tester).read(routerProvider).go('/ponds/$e1');
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Ajouter une photo'));
      final photo = await db.select(db.photos).getSingle();
      expect(
        (photo.ownerKind, photo.ownerId),
        (PhotoOwner.healthEvent, event.id),
      );
      await tapAndSettle(tester, find.byKey(ValueKey('photo-${photo.photoKey}')));
      expect(find.text('Envoyer au serveur'), findsOneWidget);
    },
    overrides: [photoCaptureProvider.overrideWithValue(capture), tempPhotoFiles()],
  );

  final store = FakePhotoStore();
  appTest(
    'a photo not on the server yet is fetched again once it is',
    (tester, db) async {
      final s = (await SetupRepository(db).currentSession())!;
      final c = appContainer(tester);
      Future<File?> look() async {
        final sub = c.listen(photoFileProvider('k1'), (_, _) {});
        await tester.runAsync(() => c.read(photoFileProvider('k1').future));
        final f = sub.read().value;
        sub.close();
        await tester.pumpAndSettle();
        return f;
      }

      expect(await look(), isNull);
      store.objects[photoPath(s.associationId, 'k1')] = tinyImage;
      expect(await look(), isNotNull);
    },
    overrides: [photoStoreProvider.overrideWithValue(store), tempPhotoFiles()],
  );
}
