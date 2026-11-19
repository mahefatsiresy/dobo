import 'package:dobo/app.dart';
import 'package:dobo/theme/dobo_theme.dart';
import 'package:dobo/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  test('scheme is ink on paper with danger as error', () {
    final t = doboTheme();
    expect(t.colorScheme.primary, const Color(0xFF17262B));
    expect(t.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(t.colorScheme.error, const Color(0xFFA3151B));
    expect(t.extension<DoboColors>(), DoboColors.standard);
    expect(t.brightness, Brightness.light);
  });

  test('type: Atkinson with Noto fallback, tabular figures on numbers', () {
    final t = doboTheme().textTheme;
    expect(t.bodyMedium!.fontFamily, 'Atkinson Hyperlegible Next');
    expect(t.bodyMedium!.fontFamilyFallback, ['Noto Sans']);
    expect(t.headlineSmall!.fontSize, 28);
    expect(
      t.headlineSmall!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(
      t.titleMedium!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    for (final s in [t.bodySmall, t.labelSmall, t.labelMedium]) {
      expect(s!.fontSize, greaterThanOrEqualTo(14));
    }
  });

  test('buttons are at least 56 dp tall', () {
    final t = doboTheme();
    for (final s in [
      t.filledButtonTheme.style!,
      t.outlinedButtonTheme.style!,
      t.textButtonTheme.style!,
    ]) {
      expect(s.minimumSize!.resolve({})!.height, 56);
    }
  });

  testWidgets('a two-digit badge count fits inside its pill', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: doboTheme(),
        home: const Scaffold(
          body: Center(
            child: Badge(label: Text('12'), child: Icon(Icons.notifications)),
          ),
        ),
      ),
    );
    final pill = t.getRect(
      find
          .descendant(of: find.byType(Badge), matching: find.byType(Container))
          .first,
    );
    // The pill lays its text out at the pill's height: measure the text's
    // own height, which is what paints.
    final style = DefaultTextStyle.of(t.element(find.text('12'))).style;
    final painter = TextPainter(
      text: TextSpan(text: '12', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(pill.height, greaterThanOrEqualTo(painter.height));
    expect(pill.width, greaterThanOrEqualTo(painter.width));
    expect(style.fontSize, greaterThanOrEqualTo(14));
    painter.dispose();
  });

  appTest('the app uses the Dobo theme', (tester, db) async {
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).colorScheme.primary, DoboColors.standard.ink);
    expect(context.dobo, DoboColors.standard);
    expect(find.byType(DoboApp), findsOneWidget);
  });
}
