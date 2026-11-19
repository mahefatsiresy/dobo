import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/date_field.dart';
import 'package:dobo/features/common/estimated.dart';
import 'package:dobo/features/common/number_field.dart';
import 'package:dobo/features/common/pond_colour.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:dobo/l10n/labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _frame(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  testWidgets('number fields use the number pad and are 56 dp tall', (
    tester,
  ) async {
    await tester.pumpWidget(
      _frame(
        NumberField(
          label: 'Poids moyen',
          controller: TextEditingController(),
          decimal: true,
          suffix: 'g',
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(
      tester.getSize(find.byType(NumberField)).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('every pond colour has a label and its own colour', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _frame(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    final labels = {for (final c in PondColour.values) l10n.pondColour(c)};
    final values = {for (final c in PondColour.values) pondColourValue(c)};
    expect(labels, hasLength(PondColour.values.length));
    expect(values, hasLength(PondColour.values.length));
  });

  testWidgets('estimated values say so', (tester) async {
    await tester.pumpWidget(_frame(const EstimatedLabel(value: '1 000')));
    expect(find.text('≈\u00a01 000'), findsOneWidget);
  });

  testWidgets('pond badge shows the code', (tester) async {
    await tester.pumpWidget(
      _frame(const PondTag(code: 'E1', colour: PondColour.yellow)),
    );
    expect(find.text('E1'), findsOneWidget);
  });

  testWidgets('a date field with a first date opens its picker there', (
    tester,
  ) async {
    await tester.pumpWidget(
      _frame(
        DateField(
          label: 'Date',
          value: DateTime(2026, 3, 12),
          firstDate: DateTime(2026, 3, 10),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();
    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(picker.firstDate, DateTime(2026, 3, 10));
  });
}
