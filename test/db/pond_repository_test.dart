import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/errors.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/session.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repo_fixtures.dart';

void main() {
  late AppDatabase db;
  late Session session;
  late PondRepository ponds;

  setUp(() async {
    (db, session) = await setUpFarm();
    ponds = PondRepository(db, session);
  });
  tearDown(() => db.close());

  test('a new pond is stamped with the session and site', () async {
    final id = await ponds.create(pondInput(' E1 ', lengthM: 30, widthM: 15));
    final p = await ponds.get(id);
    expect(
      (p.code, p.siteId, p.enteredBy, p.deviceId, p.associationId),
      (
        'E1',
        session.siteId,
        session.userId,
        session.deviceId,
        session.associationId,
      ),
    );
    expect((p.lengthM, p.status), (30.0, PondStatus.empty));
  });

  test('the same code with other case or spaces is refused', () async {
    await ponds.create(pondInput('E1'));
    await expectLater(
      ponds.create(pondInput(' e1 ')),
      throwsA(isA<DuplicateCodeException>()),
    );
  });

  test('an archived pond frees its code', () async {
    final e1 = await ponds.create(pondInput('E1'));
    await ponds.archive(e1);
    expect(await ponds.create(pondInput('E1')), isA<String>());
    expect([for (final p in await ponds.watchActive().first) p.code], ['E1']);
  });

  test(
    'renaming a pond to another pond\'s code is refused, to its own is not',
    () async {
      final e1 = await ponds.create(pondInput('E1'));
      await ponds.create(pondInput('E2'));
      await expectLater(
        ponds.update(e1, pondInput('e2')),
        throwsA(isA<DuplicateCodeException>()),
      );
      await ponds.update(e1, pondInput('e1', lengthM: 40));
      expect((await ponds.get(e1)).lengthM, 40.0);
    },
  );

  test('ponds are listed by code', () async {
    await ponds.create(pondInput('E2'));
    await ponds.create(pondInput('E1'));
    expect(
      [for (final p in await ponds.watchActive().first) p.code],
      ['E1', 'E2'],
    );
  });

  test('next free colour skips the ones in use', () async {
    final id = await ponds.create(pondInput('E1'));
    final p = await ponds.get(id);
    expect(nextFreeColour([p]), PondColour.green);
    expect(nextFreeColour([]), PondColour.blue);
  });
}
