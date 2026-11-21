import 'package:dobo/features/common/choice_buttons.dart';
import 'package:dobo/features/common/details_fold.dart';
import 'package:dobo/features/common/form_menu.dart';
import 'package:dobo/features/common/pinned_action.dart';
import 'package:dobo/features/common/pond_choice.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:dobo/l10n/mg_fallback.dart';
import 'package:dobo/theme/dobo_theme.dart';
import 'package:dobo/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures.dart';
import '../../golden_fonts.dart';

const _c = DoboColors.standard;

Widget _frame(
  Widget body, {
  Locale locale = const Locale('fr'),
  Widget? bottom,
  double textScale = 1,
}) => MaterialApp(
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
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(body: body, bottomNavigationBar: bottom),
);

/// The fill of the button around [label].
Color? _fill(WidgetTester t, Finder label) {
  final button = find.ancestor(
    of: label,
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  final style = t.widget<ButtonStyleButton>(button.first).style;
  return style?.backgroundColor?.resolve({});
}

void main() {
  group('PinnedAction', () {
    testWidgets('rides above the keyboard, 56 dp tall', (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: _frame(
            const SizedBox(),
            bottom: PinnedAction(
              icon: Icons.check,
              label: 'Transférer',
              onPressed: () {},
            ),
          ),
        ),
      );
      final button = find.widgetWithText(FilledButton, 'Transférer');
      final rect = t.getRect(button);
      expect(640 - rect.bottom, greaterThanOrEqualTo(300));
      expect(rect.height, greaterThanOrEqualTo(56));
    });

    testWidgets('null onPressed disables it', (t) async {
      await t.pumpWidget(
        _frame(
          const SizedBox(),
          bottom: const PinnedAction(
            icon: Icons.check,
            label: 'Vendre',
            onPressed: null,
          ),
        ),
      );
      expect(
        t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });
  });

  group('PondChoice', () {
    final ponds = [
      PondOption(pond: pondRow('a', code: 'E1')),
      PondOption(
        pond: pondRow('b', code: 'E2'),
        caption: 'Préparation',
      ),
      PondOption(pond: pondRow('c', code: 'E3')),
    ];

    testWidgets('a 56 dp button per pond; a tap picks it, filled', (t) async {
      String? picked;
      await t.pumpWidget(
        _frame(
          StatefulBuilder(
            builder: (context, setState) => PondChoice(
              options: ponds,
              value: picked,
              onChanged: (v) => setState(() => picked = v),
            ),
          ),
        ),
      );
      for (final code in ['E1', 'E2', 'E3']) {
        expect(find.text(code), findsOneWidget);
        final button = find.ancestor(
          of: find.text(code),
          matching: find.byType(OutlinedButton),
        );
        expect(t.getSize(button).height, greaterThanOrEqualTo(56));
      }
      expect(find.text('Préparation'), findsOneWidget);
      await t.tap(find.text('E2'));
      await t.pump();
      expect(picked, 'b');
      expect(_fill(t, find.text('E2')), _c.ink);
      expect(_fill(t, find.text('E1')), isNot(_c.ink));
    });

    testWidgets('allowNone: a second tap unpicks', (t) async {
      String? picked = 'a';
      await t.pumpWidget(
        _frame(
          PondChoice(
            options: ponds,
            value: 'a',
            allowNone: true,
            onChanged: (v) => picked = v,
          ),
        ),
      );
      await t.tap(find.text('E1'));
      expect(picked, isNull);
    });

    testWidgets('multi: taps toggle, a lone option is not picked', (t) async {
      var picked = <String>{'a'};
      await t.pumpWidget(
        _frame(
          StatefulBuilder(
            builder: (context, setState) => PondChoice(
              options: ponds,
              value: null,
              onChanged: (_) {},
              multi: true,
              values: picked,
              onChangedMany: (v) => setState(() => picked = v),
            ),
          ),
        ),
      );
      await t.tap(find.text('E2'));
      await t.pump();
      expect(picked, {'a', 'b'});
      expect(_fill(t, find.text('E2')), _c.ink);
      await t.tap(find.text('E1'));
      await t.pump();
      expect(picked, {'b'});
      Set<String>? lone;
      await t.pumpWidget(
        _frame(
          PondChoice(
            options: [ponds.first],
            value: null,
            onChanged: (_) {},
            multi: true,
            values: const {},
            onChangedMany: (v) => lone = v,
          ),
        ),
      );
      await t.pump();
      expect(lone, isNull);
    });

    testWidgets('a single option is picked by itself', (t) async {
      String? picked;
      await t.pumpWidget(
        _frame(
          PondChoice(
            options: [ponds.first],
            value: null,
            onChanged: (v) => picked = v,
          ),
        ),
      );
      await t.pump();
      expect(picked, 'a');
    });
  });

  group('ChoiceButtons', () {
    testWidgets('a tap picks; the picked one is filled', (t) async {
      String? picked = 'fresh';
      await t.pumpWidget(
        _frame(
          ChoiceButtons<String>(
            options: const [('live', 'Vivant'), ('fresh', 'Frais')],
            value: picked,
            onChanged: (v) => picked = v,
          ),
        ),
      );
      expect(_fill(t, find.text('Frais')), _c.ink);
      expect(_fill(t, find.text('Vivant')), isNot(_c.ink));
      await t.tap(find.text('Vivant'));
      expect(picked, 'live');
      final button = find.ancestor(
        of: find.text('Vivant'),
        matching: find.byType(OutlinedButton),
      );
      expect(t.getSize(button).height, greaterThanOrEqualTo(56));
    });

    testWidgets('long Malagasy labels wrap at 130 % without overflow', (
      t,
    ) async {
      t.view.physicalSize = const Size(360, 780);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        _frame(
          locale: const Locale('mg'),
          textScale: 1.3,
          ChoiceButtons<int>(
            options: const [
              (0, 'Velona'),
              (1, 'Vaovao'),
              (2, 'Novaina ho mangatsiaka'),
              (3, 'Nendasina'),
              (4, 'Namainina'),
            ],
            value: 2,
            onChanged: (_) {},
          ),
        ),
      );
      expect(t.takeException(), isNull);
      final first = t.getRect(find.text('Velona'));
      final last = t.getRect(find.text('Namainina'));
      expect(last.top, greaterThan(first.top));
    });
  });

  group('DetailsFold', () {
    testWidgets('closed until tapped, then open at once', (t) async {
      await t.pumpWidget(
        _frame(const DetailsFold(children: [Text('Écloserie')])),
      );
      expect(find.text('Plus de détails'), findsOneWidget);
      expect(find.text('Écloserie'), findsNothing);
      await t.tap(find.text('Plus de détails'));
      await t.pump();
      expect(find.text('Écloserie'), findsOneWidget);
    });

    testWidgets('initiallyOpen shows its fields', (t) async {
      await t.pumpWidget(
        _frame(
          const DetailsFold(initiallyOpen: true, children: [Text('Écloserie')]),
        ),
      );
      expect(find.text('Écloserie'), findsOneWidget);
    });

    testWidgets('a folded required field still fails and opens the fold', (
      t,
    ) async {
      final form = GlobalKey<FormState>();
      await t.pumpWidget(
        _frame(
          Form(
            key: form,
            child: DetailsFold(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Code'),
                  validator: (v) => (v ?? '').isEmpty ? 'Obligatoire' : null,
                ),
              ],
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await t.pump();
      expect(find.text('Obligatoire'), findsOneWidget);
    });
  });

  group('confirmDelete and showDone', () {
    testWidgets('confirmDelete shows the message and answers', (t) async {
      bool? answer;
      await t.pumpWidget(
        _frame(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  answer = await confirmDelete(context, 'Supprimer la vente ?'),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(find.text('Supprimer la vente ?'), findsOneWidget);
      await t.tap(find.text('Supprimer'));
      await t.pumpAndSettle();
      expect(answer, isTrue);
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      await t.tap(find.text('Annuler'));
      await t.pumpAndSettle();
      expect(answer, isFalse);
    });

    testWidgets('showDone shows the verb with a tick', (t) async {
      await t.pumpWidget(
        _frame(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showDone(context, 'Transféré'),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pump();
      expect(find.text('Transféré'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // Clear of a pinned action (80 dp) at the foot of the next page.
      final screen = t.getSize(find.byType(Scaffold).first).height;
      expect(
        screen - t.getRect(find.text('Transféré')).bottom,
        greaterThanOrEqualTo(80),
      );
    });

    testWidgets('FormMenu lists its entries behind ⋮', (t) async {
      var deleted = false;
      await t.pumpWidget(
        MaterialApp(
          theme: doboTheme(),
          home: Scaffold(
            appBar: AppBar(
              actions: [
                FormMenu(
                  entries: [
                    FormMenuEntry(
                      label: 'Supprimer',
                      icon: Icons.delete_outline,
                      onTap: () => deleted = true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.byIcon(Icons.more_vert));
      await t.pumpAndSettle();
      await t.tap(find.text('Supprimer'));
      await t.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });

  testWidgets('form pieces golden', (t) async {
    await loadAppFonts();
    t.view.physicalSize = const Size(720, 1280);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      _frame(
        ColoredBox(
          key: const Key('pieces'),
          color: _c.paper,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PondChoice(
                options: [
                  PondOption(pond: pondRow('a', code: 'E1')),
                  PondOption(
                    pond: pondRow('b', code: 'E2'),
                    caption: '≈ 900 poissons',
                  ),
                  PondOption(
                    pond: pondRow('c', code: 'P1'),
                    caption: 'Vide',
                  ),
                ],
                value: 'b',
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              ChoiceButtons<int>(
                options: const [
                  (0, 'Vivant'),
                  (1, 'Frais'),
                  (2, 'Congelé'),
                  (3, 'Fumé'),
                  (4, 'Séché'),
                ],
                value: 1,
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              const DetailsFold(children: [Text('Écloserie')]),
            ],
          ),
        ),
        bottom: PinnedAction(
          icon: Icons.storefront,
          label: 'Vendre',
          onPressed: () {},
        ),
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/form_pieces.png'),
    );
  });
}
