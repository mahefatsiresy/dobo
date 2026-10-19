import 'package:dobo/l10n/formatting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
