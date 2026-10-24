import 'package:dobo/db/database.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  DailyLogsCompanion log({Set<WarningSign>? signs}) => DailyLogsCompanion.insert(
        associationId: 'a1',
        enteredBy: 'u1',
        deviceId: 'd1',
        recordedAt: DateTime.utc(2026, 3, 1, 9),
        pondId: 'p1',
        feedGivenG: 4200,
        warningSigns: signs == null ? const Value.absent() : Value(signs),
      );

  test('warning signs round-trip as a set', () async {
    await db.into(db.dailyLogs).insert(
        log(signs: {WarningSign.whiteSpots, WarningSign.rubbing}));
    final row = await db.select(db.dailyLogs).getSingle();
    expect(row.warningSigns, {WarningSign.rubbing, WarningSign.whiteSpots});
  });

  test('no signs read back as an empty set; defaults are 0 and false',
      () async {
    await db.into(db.dailyLogs).insert(log());
    final row = await db.select(db.dailyLogs).getSingle();
    expect(row.warningSigns, isEmpty);
    expect(row.deathSigns, isEmpty);
    expect((row.deaths, row.ateFast), (0, false));
    expect(row.visitId, isNull);
  });

  test('a sign this version does not know is skipped, not a crash', () async {
    await db.into(db.dailyLogs).insert(log());
    await db.customStatement(
        "UPDATE daily_logs SET warning_signs = 'rubbing,someFutureSign'");
    final row = await db.select(db.dailyLogs).getSingle();
    expect(row.warningSigns, {WarningSign.rubbing});
  });

  test('health actions round-trip', () async {
    await db.into(db.healthEvents).insert(HealthEventsCompanion.insert(
          associationId: 'a1',
          enteredBy: 'u1',
          deviceId: 'd1',
          recordedAt: DateTime.utc(2026, 3, 1, 9),
          pondId: 'p1',
          actions: {HealthAction.isolated, HealthAction.technicianCalled},
        ));
    final row = await db.select(db.healthEvents).getSingle();
    expect(row.actions, {HealthAction.isolated, HealthAction.technicianCalled});
    expect(row.signs, isEmpty);
  });

  test('a visit starts open', () async {
    await db.into(db.visits).insert(VisitsCompanion.insert(
          associationId: 'a1',
          enteredBy: 'u1',
          deviceId: 'd1',
          siteId: 's1',
          startedAt: DateTime.utc(2026, 3, 1, 6),
        ));
    final v = await db.select(db.visits).getSingle();
    expect((v.endedAt, v.summary), (null, null));
  });
}
