import 'package:dobo/db/database.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a member row round-trips with its defaults', () async {
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: const Value('m1'),
            associationId: 'a1',
            enteredBy: 'm0',
            deviceId: 'd1',
            name: 'Rakoto',
            role: MemberRole.worker,
            locale: 'mg',
            login: const Value('rakoto'),
          ),
        );
    final m = await db.select(db.members).getSingle();
    expect(
      (m.name, m.role, m.isAdmin, m.isSales, m.active, m.locale, m.login),
      ('Rakoto', MemberRole.worker, false, false, true, 'mg', 'rakoto'),
    );
    expect((m.groupId, m.personId), (null, null));
  });

  test('a setting override may hold no value', () async {
    await db
        .into(db.settingOverrides)
        .insert(
          SettingOverridesCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm0',
            deviceId: 'd1',
            siteId: 's1',
            key: 'minOxygenMgL',
          ),
        );
    final o = await db.select(db.settingOverrides).getSingle();
    expect((o.key, o.value), ('minOxygenMgL', null));
  });

  test('a group has a name', () async {
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm0',
            deviceId: 'd1',
            name: 'Branche Rabe',
          ),
        );
    expect((await db.select(db.groups).getSingle()).name, 'Branche Rabe');
  });
}
