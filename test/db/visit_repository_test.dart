import 'dart:io';

import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/repositories/visit_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late VisitRepository visits;

  setUp(() async {
    (db, session) = await setUpFarm();
    visits = VisitRepository(db, session);
  });
  tearDown(() => db.close());

  test('one open visit at a time', () async {
    final id = await visits.start();
    expect((await visits.watchOpen().first)!.id, id);
    await expectLater(visits.start(), throwsStateError);
  });

  test('ending a visit keeps its summary and closes it', () async {
    final id = await visits.start();
    await visits.setSummary(id, 'Tout va bien');
    await visits.end(id);
    expect(await visits.watchOpen().first, isNull);
    final v = (await visits.watchAll().first).single;
    expect((v.summary, v.endedAt != null), ('Tout va bien', true));
    expect(await visits.start(), isA<String>());
  });

  test('observations belong to the visit they were made in', () async {
    final id = await visits.start();
    final obs = ObservationRepository(db, session, visitId: id);
    await obs.addObservation(category: ObservationCategory.dike, ok: true);
    await obs.addObservation(
      category: ObservationCategory.other,
      note: 'Clôture ouverte',
    );
    final list = await obs.watchForVisit(id).first;
    expect(list.map((o) => o.category).toSet(), {
      ObservationCategory.dike,
      ObservationCategory.other,
    });
    expect(list.every((o) => o.siteId == session.siteId), isTrue);
  });

  test('an open visit survives the app being killed', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = await Directory.systemTemp.createTemp('dobo_visit');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/dobo.sqlite');
    var onDisk = AppDatabase(NativeDatabase(file));
    final s = await SetupRepository(onDisk).completeSetup(siteName: 'Ambo');
    final id = await VisitRepository(onDisk, s).start();
    await onDisk.close();

    onDisk = AppDatabase(NativeDatabase(file));
    final again = (await SetupRepository(onDisk).currentSession())!;
    expect((await VisitRepository(onDisk, again).watchOpen().first)!.id, id);
    await onDisk.close();
  });
}
