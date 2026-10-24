import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/big_number_field.dart';
import 'package:dobo/features/common/colour_swatches.dart';
import 'package:dobo/features/common/leftover_picker.dart';
import 'package:dobo/features/common/sign_grid.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:dobo/l10n/labels.dart';
import 'package:dobo/l10n/mg_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _frame(Widget child, {Locale locale = const Locale('mg')}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('mg')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...mgFallbackDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  test(
    'signs, leftovers and water colours have their own labels in fr and mg',
    () {
      for (final locale in const [Locale('fr'), Locale('mg')]) {
        final l10n = lookupAppLocalizations(locale);
        expect({
          for (final s in WarningSign.values) l10n.warningSign(s),
        }, hasLength(WarningSign.values.length));
        expect({
          for (final l in Leftover.values) l10n.leftover(l),
        }, hasLength(Leftover.values.length));
        expect({
          for (final c in WaterColour.values) l10n.waterColour(c),
        }, hasLength(WaterColour.values.length));
      }
      expect(
        lookupAppLocalizations(const Locale('mg')).leftover(Leftover.lots),
        isNot(
          lookupAppLocalizations(const Locale('fr')).leftover(Leftover.lots),
        ),
      );
    },
  );

  testWidgets('the sign grid toggles a sign on and off', (tester) async {
    var selected = <WarningSign>{};
    await tester.pumpWidget(
      _frame(
        StatefulBuilder(
          builder: (context, setState) => SignGrid(
            options: WarningSign.values.toSet(),
            selected: selected,
            onChanged: (s) => setState(() => selected = s),
          ),
        ),
      ),
    );
    final rubbing = find.text(
      lookupAppLocalizations(const Locale('mg'))
          .warningSign(WarningSign.rubbing),
    );
    await tester.tap(rubbing);
    await tester.pump();
    expect(selected, {WarningSign.rubbing});
    await tester.tap(rubbing);
    await tester.pump();
    expect(selected, isEmpty);
    final tile = tester.getSize(
      find.byKey(const ValueKey(WarningSign.rubbing)),
    );
    expect(tile.width >= 56 && tile.height >= 56, isTrue);
  });

  testWidgets('tapping the chosen water colour clears it', (tester) async {
    WaterColour? value;
    await tester.pumpWidget(
      _frame(
        StatefulBuilder(
          builder: (context, setState) => ColourSwatches(
            value: value,
            onChanged: (c) => setState(() => value = c),
          ),
        ),
      ),
    );
    final swatch = find.byKey(const ValueKey(WaterColour.darkGreen));
    await tester.tap(swatch);
    await tester.pump();
    expect(value, WaterColour.darkGreen);
    await tester.tap(swatch);
    await tester.pump();
    expect(value, isNull);
    final size = tester.getSize(swatch);
    expect(size.width >= 56 && size.height >= 56, isTrue);
  });

  testWidgets('"ate fast" only appears once "none" is chosen', (tester) async {
    Leftover? leftover;
    var fast = false;
    final l10n = lookupAppLocalizations(const Locale('mg'));
    await tester.pumpWidget(
      _frame(
        StatefulBuilder(
          builder: (context, setState) => LeftoverPicker(
            value: leftover,
            ateFast: fast,
            onChanged: (l, f) => setState(() {
              leftover = l;
              fast = f;
            }),
          ),
        ),
      ),
    );
    expect(find.text(l10n.ateFast), findsNothing);
    await tester.tap(find.text(l10n.leftover(Leftover.none)));
    await tester.pump();
    await tester.tap(find.text(l10n.ateFast));
    await tester.pump();
    expect((leftover, fast), (Leftover.none, true));
    await tester.tap(find.text(l10n.leftover(Leftover.some)));
    await tester.pump();
    expect((leftover, fast), (Leftover.some, false));
    expect(find.text(l10n.ateFast), findsNothing);
  });

  testWidgets('the big number field shows the target and uses the keypad', (
    tester,
  ) async {
    await tester.pumpWidget(
      _frame(
        BigNumberField(
          label: 'Sakafo',
          controller: TextEditingController(),
          decimal: true,
          suffix: 'kg',
          hint: '≈ 4,2 kg',
        ),
      ),
    );
    expect(find.text('≈ 4,2 kg'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThanOrEqualTo(72),
    );
  });
}
