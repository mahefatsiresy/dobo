import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// `intl` has no Malagasy data; Malagasy users get French number and date
/// conventions (decimal comma), which match local usage.
String intlLocaleFor(Locale locale) =>
    locale.languageCode == 'mg' ? 'fr' : locale.languageCode;

String formatKg(int grams, Locale locale) =>
    '${NumberFormat('#,##0.#', intlLocaleFor(locale)).format(grams / 1000)} kg';
