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

  test('UTC inputs count in local calendar days', () {
    final lateNight = DateTime(2026, 3, 1, 23, 59);
    final earlyMorning = DateTime(2026, 3, 2, 0, 1);
    expect(daysBetween(lateNight.toUtc(), earlyMorning.toUtc()), 1);
    expect(daysBetween(lateNight, earlyMorning.toUtc()), 1);
  });
}
