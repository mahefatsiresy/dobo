import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/common/estimated.dart';
import 'package:dobo/features/common/pond_colour.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:dobo/l10n/mg_fallback.dart';
import 'package:dobo/theme/dobo_theme.dart';
import 'package:dobo/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../golden_fonts.dart';

const _c = DoboColors.standard;

Widget _frame(Widget child, {Locale locale = const Locale('fr')}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: doboTheme(),
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('mg')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...mgFallbackDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

/// The colour a widget's [Text] is painted in.
Color? _textColour(WidgetTester t, Finder text) =>
    t.widget<Text>(text).style?.color ??
    DefaultTextStyle.of(t.element(text)).style.color;

void main() {
  testWidgets('estimated value starts with ≈ and reads "estimé" aloud', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(_frame(const EstimatedLabel(value: '1 240')));
    expect(find.text('≈ 1 240'), findsOneWidget);
    expect(find.text('estimé'), findsNothing);
    expect(find.bySemanticsLabel('1 240 estimé'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('danger band is filled danger with white text', (t) async {
    await t.pumpWidget(
      _frame(
        const AttentionBand(severity: BandSeverity.danger, text: 'Oxygène'),
      ),
    );
    final box = t.widget<Container>(
      find
          .descendant(
            of: find.byType(AttentionBand),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((box.decoration! as BoxDecoration).color, _c.danger);
    expect(_textColour(t, find.text('Oxygène')), _c.paper);
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(
      t.getSize(find.byType(AttentionBand)).height,
      greaterThanOrEqualTo(40),
    );
  });

  testWidgets('warning band is warningFill with a warning left edge', (
    t,
  ) async {
    await t.pumpWidget(
      _frame(
        const AttentionBand(severity: BandSeverity.warning, text: 'Pesée'),
      ),
    );
    final box = t.widget<Container>(
      find
          .descendant(
            of: find.byType(AttentionBand),
            matching: find.byType(Container),
          )
          .first,
    );
    final d = box.decoration! as BoxDecoration;
    expect(d.color, _c.warningFill);
    expect((d.border! as Border).left.color, _c.warning);
    expect((d.border! as Border).left.width, 4);
    expect(_textColour(t, find.text('Pesée')), _c.ink);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  });

  testWidgets('tag: black on yellow, white on blue', (t) async {
    await t.pumpWidget(
      _frame(
        const Column(
          children: [
            PondTag(code: 'E1', colour: PondColour.yellow),
            PondTag(code: 'E2', colour: PondColour.blue),
          ],
        ),
      ),
    );
    expect(_textColour(t, find.text('E1')), Colors.black);
    expect(_textColour(t, find.text('E2')), Colors.white);
    expect(
      t.getSize(find.byType(PondTag).first).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('pond code: ink code beside a 12 dp swatch of its colour', (
    t,
  ) async {
    await t.pumpWidget(
      _frame(const PondCode(code: 'E2', colour: PondColour.yellow)),
    );
    expect(_textColour(t, find.text('E2')), _c.ink);
    final swatch = find.byKey(const ValueKey('pondSwatch'));
    expect(t.getSize(swatch), const Size(12, 12));
    final box = t.widget<Container>(swatch);
    expect(
      (box.decoration! as BoxDecoration).color,
      pondColourValue(PondColour.yellow),
    );
  });

  testWidgets('building blocks golden', (t) async {
    await loadAppFonts();
    t.view.physicalSize = const Size(720, 1560);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      _frame(
        locale: const Locale('mg'),
        Builder(
          builder: (context) {
            final text = Theme.of(context).textTheme;
            return ColoredBox(
              key: const Key('blocks'),
              color: _c.paper,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Row(
                    children: [
                      PondTag(code: 'E1', colour: PondColour.yellow),
                      SizedBox(width: 8),
                      PondTag(code: 'E2', colour: PondColour.blue),
                      SizedBox(width: 8),
                      PondTag(code: 'E10', colour: PondColour.black),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      PondCode(code: 'E1', colour: PondColour.yellow),
                      SizedBox(width: 16),
                      PondCode(code: 'E2', colour: PondColour.blue),
                      SizedBox(width: 16),
                      PondCode(code: 'P1', colour: PondColour.black),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const AttentionBand(
                    severity: BandSeverity.danger,
                    text:
                        'Ambany loatra ny oksizenina ao amin\'ny E2, '
                        'ary misy fanairana 2 hafa',
                  ),
                  const SizedBox(height: 8),
                  const AttentionBand(
                    severity: BandSeverity.warning,
                    text: 'Tokony holanjaina ny trondro ao amin\'ny E3',
                  ),
                  const SizedBox(height: 16),
                  EstimatedLabel(value: '2,4 kg', style: text.headlineSmall),
                  const EstimatedLabel(value: '1 240'),
                  EstimatedLabel(value: '186 kg', style: text.bodySmall),
                ],
              ),
            );
          },
        ),
      ),
    );
    await expectLater(
      find.byKey(const Key('blocks')),
      matchesGoldenFile('goldens/building_blocks.png'),
    );
  });
}
