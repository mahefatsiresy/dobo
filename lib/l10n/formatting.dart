import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../domain/dates.dart';

/// `intl` has no Malagasy data; Malagasy users get French number and date
/// conventions (decimal comma), which match local usage.
String intlLocaleFor(Locale locale) =>
    locale.languageCode == 'mg' ? 'fr' : locale.languageCode;

String formatKg(int grams, Locale locale) =>
    '${NumberFormat('#,##0.#', intlLocaleFor(locale)).format(grams / 1000)} kg';

/// A number typed by hand: `,` or `.` as decimal mark, spaces ignored.
/// Empty or unreadable text is no value.
double? parseDecimal(String text) {
  final cleaned = text.replaceAll(RegExp(r'[\s  ]'), '');
  if (!RegExp(r'^-?\d*[.,]?\d+$|^-?\d+[.,]$').hasMatch(cleaned)) return null;
  return double.tryParse(cleaned.replaceAll(',', '.'));
}

/// `dd/mm/yyyy` of the Madagascar calendar day.
String formatDate(DateTime t) => DateFormat('dd/MM/yyyy').format(farmDate(t));

/// Average weight: `12,5 g`, at most one decimal.
String formatGrams(double grams, Locale locale) =>
    '${NumberFormat('#,##0.#', intlLocaleFor(locale)).format(grams)} g';

/// Fish counts with thousands separators: `1 000`.
String formatCount(int n, Locale locale) =>
    NumberFormat.decimalPattern(intlLocaleFor(locale)).format(n);

/// A decimal with a fixed number of decimals: `3,0`.
String formatDecimal(double v, Locale locale, {int decimals = 1}) =>
    NumberFormat.decimalPatternDigits(
      locale: intlLocaleFor(locale),
      decimalDigits: decimals,
    ).format(v);
