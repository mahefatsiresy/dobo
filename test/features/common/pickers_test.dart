import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/choice_tile.dart';
import 'package:dobo/features/common/colour_swatches.dart';
import 'package:dobo/features/common/option_button.dart';
import 'package:dobo/features/common/picker_screen.dart';
import 'package:dobo/features/common/sign_grid.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:dobo/l10n/mg_fallback.dart';
import 'package:dobo/theme/dobo_theme.dart';
import 'package:dobo/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../golden_fonts.dart';

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
      home: child,
    );

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(720, 1560);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('signs are two per row and every Malagasy label shows whole', (
    t,
  ) async {
    _phone(t);
    await t.pumpWidget(
      _frame(
        locale: const Locale('mg'),
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SignGrid(
              options: WarningSign.values.toSet(),
              selected: const {},
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    final tiles = find.byType(ChoiceTile);
    final y = [for (var i = 0; i < 3; i++) t.getTopLeft(tiles.at(i)).dy];
    expect(y[0], y[1]);
    expect(y[2], greaterThan(y[1]));
    for (final p in t.renderObjectList<RenderParagraph>(
      find.descendant(of: tiles, matching: find.byType(RichText)),
    )) {
      expect(p.maxLines, isNull);
      expect(p.didExceedMaxLines, isFalse);
    }
  });

  testWidgets('a picked tile is ink with white text, readable in sunlight', (
    t,
  ) async {
    _phone(t);
    await t.pumpWidget(
      _frame(
        Scaffold(
          body: SignGrid(
            options: const {WarningSign.rubbing, WarningSign.whiteSpots},
            selected: const {WarningSign.rubbing},
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final c = DoboColors.standard;
    Color? textColour(WarningSign s) {
      final text = find.descendant(
        of: find.byKey(ValueKey(s)),
        matching: find.byType(Text),
      );
      return DefaultTextStyle.of(t.element(text)).style
          .merge(t.widget<Text>(text).style)
          .color;
    }

    final box = t.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey(WarningSign.rubbing)),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((box.decoration! as BoxDecoration).color, c.ink);
    expect(textColour(WarningSign.rubbing), c.paper);
    expect(textColour(WarningSign.whiteSpots), c.ink);
  });

  testWidgets('water colours are two per row', (t) async {
    _phone(t);
    await t.pumpWidget(
      _frame(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ColourSwatches(onChanged: (_) {}),
          ),
        ),
      ),
    );
    final tiles = find.byType(ChoiceTile);
    expect(t.getTopLeft(tiles.at(0)).dy, t.getTopLeft(tiles.at(1)).dy);
    expect(
      t.getTopLeft(tiles.at(2)).dy,
      greaterThan(t.getTopLeft(tiles.at(1)).dy),
    );
  });

  Future<Set<WarningSign>?> openSigns(
    WidgetTester t,
    Future<void> Function() inside,
  ) async {
    Set<WarningSign>? result;
    var returned = false;
    await t.pumpWidget(
      _frame(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<Set<WarningSign>>(
                    MaterialPageRoute(
                      builder: (_) => PickerScreen<Set<WarningSign>>(
                        title: 'Signes',
                        doneLabel: 'Terminé',
                        initial: const {WarningSign.rubbing},
                        builder: (context, value, onChanged) => SignGrid(
                          options: WarningSign.values.toSet(),
                          selected: value,
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                  );
                  returned = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await inside();
    await t.pumpAndSettle();
    expect(returned, isTrue);
    return result;
  }

  testWidgets('a picker returns what was picked on Terminé', (t) async {
    _phone(t);
    final picked = await openSigns(t, () async {
      await t.tap(find.byKey(const ValueKey(WarningSign.whiteSpots)));
      await t.pump();
      await t.tap(find.text('Terminé'));
    });
    expect(picked, {WarningSign.rubbing, WarningSign.whiteSpots});
  });

  testWidgets('back from a picker returns nothing', (t) async {
    _phone(t);
    final picked = await openSigns(t, () async {
      await t.tap(find.byKey(const ValueKey(WarningSign.whiteSpots)));
      await t.pump();
      await t.tap(find.byType(BackButton));
    });
    expect(picked, isNull);
  });

  testWidgets('an option button shows what was picked, at least 72 dp', (
    t,
  ) async {
    _phone(t);
    await t.pumpWidget(
      _frame(
        Scaffold(
          body: Row(
            children: [
              Expanded(
                child: OptionButton(title: 'Signes', onTap: () {}),
              ),
              Expanded(
                child: OptionButton(
                  title: 'Repas',
                  picked: const Text('3'),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    for (final b in t.widgetList(find.byType(OptionButton))) {
      expect(t.getSize(find.byWidget(b)).height, greaterThanOrEqualTo(72));
    }
  });

  testWidgets('signs picker golden in Malagasy', (t) async {
    _phone(t);
    await t.pumpWidget(
      _frame(
        locale: const Locale('mg'),
        PickerScreen<Set<WarningSign>>(
          title: 'Famantarana',
          doneLabel: 'Vita',
          initial: const {WarningSign.rubbing, WarningSign.whiteSpots},
          builder: (context, value, onChanged) => SignGrid(
            options: WarningSign.values.toSet(),
            selected: value,
            onChanged: onChanged,
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(PickerScreen<Set<WarningSign>>),
      matchesGoldenFile('goldens/signs_mg.png'),
    );
  });
}
