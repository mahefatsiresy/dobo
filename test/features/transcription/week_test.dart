import 'package:dobo/features/transcription/week.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a farm week runs Monday to Sunday', () {
    final week = weekOf(DateTime(2026, 4, 1)); // a Wednesday
    expect(week.first, DateTime(2026, 3, 30));
    expect(week.last, DateTime(2026, 4, 5));
    expect(week, hasLength(7));
    expect(weekOf(DateTime(2026, 3, 30)).first, DateTime(2026, 3, 30));
    expect(weekOf(DateTime(2026, 4, 5)).first, DateTime(2026, 3, 30));
  });

  test('the week crosses a year end', () {
    expect(weekOf(DateTime(2027, 1, 1)).first, DateTime(2026, 12, 28));
    expect(weekOf(DateTime(2027, 1, 1)).last, DateTime(2027, 1, 3));
  });
}
