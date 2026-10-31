import 'package:dobo/domain/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts calendar days, ignoring time of day', () {
    expect(
      daysBetween(DateTime(2026, 3, 1, 23, 59), DateTime(2026, 3, 2, 0, 1)),
      1,
    );
    expect(
      daysBetween(DateTime(2026, 3, 1, 0, 1), DateTime(2026, 3, 1, 23, 59)),
      0,
    );
  });

  test('crosses month ends and goes negative backwards', () {
    expect(daysBetween(DateTime(2026, 2, 28), DateTime(2026, 3, 1)), 1);
    expect(daysBetween(DateTime(2026, 3, 10), DateTime(2026, 3, 1)), -9);
  });

  test('UTC inputs count in Madagascar days, whatever the phone zone', () {
    final lateNight = DateTime.utc(2026, 3, 1, 20); // 23:00 on 01/03 in Tana
    final afterMidnight = DateTime.utc(2026, 3, 1, 21, 30); // 00:30 on 02/03
    expect(daysBetween(lateNight, afterMidnight), 1);
    expect(daysBetween(DateTime(2026, 3, 1, 23), afterMidnight), 1);
    expect(daysBetween(afterMidnight, DateTime(2026, 3, 2, 8)), 0);
  });

  test('a date entered by hand is stored as noon in Madagascar', () {
    expect(farmDateToUtc(DateTime(2026, 3, 1)), DateTime.utc(2026, 3, 1, 9));
    expect(
      farmDateToUtc(DateTime(2026, 3, 1, 23, 30)),
      DateTime.utc(2026, 3, 1, 9),
    );
    expect(
      daysBetween(
        farmDateToUtc(DateTime(2026, 3, 1)),
        farmDateToUtc(DateTime(2026, 3, 15)),
      ),
      14,
    );
  });

  test('farmDate gives the Madagascar calendar day', () {
    expect(farmDate(DateTime.utc(2026, 3, 1, 21, 30)), DateTime(2026, 3, 2));
    expect(farmDate(DateTime.utc(2026, 3, 1, 20, 59)), DateTime(2026, 3, 1));
    expect(farmDate(DateTime(2026, 3, 1, 23, 59)), DateTime(2026, 3, 1));
  });

  test('a time read on the farm clock is stored in UTC', () {
    expect(
      farmTimeToUtc(DateTime(2026, 3, 2), 6, 30),
      DateTime.utc(2026, 3, 2, 3, 30),
    );
    expect(
      farmTimeToUtc(DateTime(2026, 3, 2), 1, 0),
      DateTime.utc(2026, 3, 1, 22),
    );
  });

  test('farmDayNumber counts farm days, so differences match daysBetween', () {
    final a = DateTime.utc(2026, 3, 9, 20, 59); // 23:59 on 09/03 farm time
    final b = DateTime.utc(2026, 3, 9, 21); // 00:00 on 10/03 farm time
    expect(farmDayNumber(b) - farmDayNumber(a), 1);
    expect(
      farmDayNumber(DateTime(2026, 4, 2)) - farmDayNumber(DateTime(2026, 3, 1)),
      daysBetween(DateTime(2026, 3, 1), DateTime(2026, 4, 2)),
    );
  });
}
