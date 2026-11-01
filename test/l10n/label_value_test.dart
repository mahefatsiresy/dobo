import 'package:dobo/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a label and its value are joined by the ARB pattern', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(fr.labelValue('Morts', '3'), 'Morts : 3');
    expect(fr.labelColon('Poissons'), 'Poissons :');
    final mg = lookupAppLocalizations(const Locale('mg'));
    expect(mg.labelValue('Maty', '3'), 'Maty : 3');
  });
}
