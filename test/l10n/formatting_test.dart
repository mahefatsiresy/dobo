import 'package:dobo/l10n/formatting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const fr = Locale('fr');

void main() {
  test('Malagasy formats numbers with French conventions', () {
    expect(intlLocaleFor(const Locale('mg')), 'fr');
    expect(intlLocaleFor(const Locale('fr')), 'fr');
  });

  test('formatKg shows kilograms with a decimal comma', () {
    expect(formatKg(12500, const Locale('fr')), '12,5 kg');
    expect(formatKg(12500, const Locale('mg')), '12,5 kg');
    expect(formatKg(3000, const Locale('fr')), '3 kg');
    expect(formatKg(500, const Locale('mg')), '0,5 kg');
  });

  test('decimal comma or dot, spaces ignored, junk is no value', () {
    expect(parseDecimal('12,5'), 12.5);
    expect(parseDecimal(' 12.5 '), 12.5);
    expect(parseDecimal('1 250,5'), 1250.5);
    expect(parseDecimal('1\u202f250'), 1250.0);
    expect(parseDecimal('40'), 40.0);
    expect(parseDecimal(''), isNull);
    expect(parseDecimal('abc'), isNull);
    expect(parseDecimal('NaN'), isNull);
    expect(parseDecimal('12,5,1'), isNull);
  });

  test('dates show as dd/mm/yyyy in Madagascar', () {
    expect(formatDate(DateTime.utc(2026, 3, 1, 21, 30)), '02/03/2026');
    expect(formatDate(DateTime(2026, 12, 9)), '09/12/2026');
  });

  test('grams, counts and decimals', () {
    expect(formatGrams(12.5, fr), '12,5 g');
    expect(formatGrams(250, fr), '250 g');
    expect(formatGrams(12.55, const Locale('mg')), '12,6 g');
    expect(formatCount(1000, fr), '1\u202f000');
    expect(formatDecimal(3, fr), '3,0');
    expect(formatDecimal(2.222, fr, decimals: 2), '2,22');
  });

  test('plain numbers and numbers for editing', () {
    expect(formatNumber(1000, fr), '1\u202f000');
    expect(formatNumber(2.5, fr), '2,5');
    expect(formatNumber(3, fr), '3');
    expect(formatForInput(30.5), '30,5');
    expect(formatForInput(1250), '1250');
    expect(parseDecimal(formatForInput(0.125)), 0.125);
  });
}
