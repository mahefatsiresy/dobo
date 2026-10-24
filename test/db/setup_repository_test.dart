import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SetupRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SetupRepository(db);
  });
  tearDown(() => db.close());

  test('no session before setup', () async {
    expect(await repo.currentSession(), isNull);
  });

  test('setup creates the site and a session that persists', () async {
    final s = await repo.completeSetup(
      siteName: 'Ambohidratrimo',
      locationNote: 'Route RN4',
    );
    expect(
      await repo.currentSession(),
      isA<Session>()
          .having((x) => x.siteId, 'siteId', s.siteId)
          .having((x) => x.userId, 'userId', s.userId)
          .having((x) => x.associationId, 'associationId', s.associationId),
    );
    expect(s.deviceId, await db.deviceId());
    final site = await db.select(db.sites).getSingle();
    expect(
      (site.id, site.name, site.locationNote, site.enteredBy),
      (s.siteId, 'Ambohidratrimo', 'Route RN4', s.userId),
    );
    expect(site.associationId, s.associationId);
  });

  test('setup runs only once', () async {
    await repo.completeSetup(siteName: 'Ambohidratrimo');
    await expectLater(repo.completeSetup(siteName: 'X'), throwsStateError);
    expect(await db.select(db.sites).get(), hasLength(1));
  });
}
