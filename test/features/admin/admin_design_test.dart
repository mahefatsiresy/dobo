import 'package:dobo/db/database.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/choice_buttons.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _clock = clockProvider.overrideWithValue(() => demoNow);

void _adminTest(
  String description,
  String Function(AppDatabase db, Map<String, String> ids) path,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  Size size = const Size(360, 1200),
}) => appTest(description, overrides: [_clock], (tester, db) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await seedDemoAdmin(db, await seedDemoFarm(db));
  final ids = {for (final m in await db.select(db.members).get()) m.name: m.id};
  await tester.pumpAndSettle();
  appContainer(tester).read(routerProvider).go(path(db, ids));
  await tester.pumpAndSettle();
  await body(tester, db);
});

Finder _pinned(String label) => find.descendant(
  of: find.byType(SafeArea),
  matching: find.widgetWithText(FilledButton, label),
);

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await loadAppFonts();
  });

  _adminTest('Administration: a summary on each row', (_, _) => '/more/admin', (
    tester,
    db,
  ) async {
    expect(find.text('2 actifs, aucun ouvrier'), findsOneWidget);
    expect(find.text('1 branche'), findsOneWidget);
    expect(find.text('1 valeur modifiée'), findsOneWidget);
  });

  _adminTest(
    'Members: vous, role and group, a last row to add',
    (_, _) => '/more/admin/members',
    (tester, db) async {
      expect(find.textContaining('vous'), findsOneWidget);
      expect(find.textContaining('Rabe'), findsWidgets);
      expect(find.text('Ajouter un membre'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );

  _adminTest(
    'Member form: buttons, a group picker, resets in ⋮',
    (_, ids) => '/more/admin/members/${ids['Hery']}',
    (tester, db) async {
      expect(find.byType(ChoiceButtons<MemberRole>), findsOneWidget);
      expect(find.byType(ChoiceButtons<String>), findsOneWidget); // language
      expect(
        find.byWidgetPredicate(
          (w) => w is SegmentedButton || w is DropdownButtonFormField,
        ),
        findsNothing,
      );
      expect(find.text('Membre'), findsWidgets);
      expect(_pinned('Enregistrer'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const Key('memberGroup')));
      await tapAndSettle(tester, find.text('Aucune'));
      expect(find.byKey(const Key('memberGroup')), findsOneWidget);
    },
  );

  _adminTest(
    'Groups and people: last rows to add, no FAB',
    (_, _) => '/more/admin/groups',
    (tester, db) async {
      expect(find.text('Ajouter une branche'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      appContainer(tester).read(routerProvider).go('/more/people');
      await tester.pumpAndSettle();
      expect(find.text('Ajouter une personne'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Soa'), findsNothing); // inactive, folded
      await tapAndSettle(tester, find.text('Inactifs'));
      expect(find.text('Soa'), findsOneWidget);
    },
  );

  _adminTest(
    'Settings: sections folded; Rétablir puts the handbook back',
    (_, _) => '/more/admin/settings',
    (tester, db) async {
      expect(find.text('1 modifiée'), findsOneWidget);
      expect(find.byKey(const Key('setting-minOxygenMgL')), findsNothing);
      await tapAndSettle(tester, find.text("Qualité de l'eau"));
      final row = find.byKey(const Key('setting-minOxygenMgL'));
      expect(row, findsOneWidget);
      await tapAndSettle(
        tester,
        find.descendant(of: row, matching: find.text('Rétablir')),
      );
      await tapAndSettle(tester, _pinned('Enregistrer'));
      final overrides = await (db.select(
        db.settingOverrides,
      )..where((o) => o.key.equals('minOxygenMgL'))).get();
      expect(overrides.single.value, isNull);
    },
  );

  for (final path in [
    '/more/admin',
    '/more/admin/members',
    '/more/admin/groups',
    '/more/admin/settings',
    '/more/people',
  ]) {
    _adminTest('$path: large Malagasy text does not overflow', (_, _) => path, (
      tester,
      db,
    ) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final (name, path)
      in <(String, String Function(AppDatabase, Map<String, String>))>[
        ('admin_fr', (_, _) => '/more/admin'),
        ('members_fr', (_, _) => '/more/admin/members'),
        ('member_fr', (_, ids) => '/more/admin/members/${ids['Hery']}'),
        ('settings_fr', (_, _) => '/more/admin/settings'),
      ]) {
    _adminTest('$name golden', path, (tester, db) async {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    }, size: const Size(360, 780));
  }
}
