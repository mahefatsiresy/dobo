import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/daily_log_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/common/pictograms.dart';
import 'package:dobo/features/daily_log/stop_feeding_sign.dart';
import 'package:dobo/features/ponds/pond_overview.dart';
import 'package:dobo/l10n/formatting.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

final _day = DateTime(2026, 3, 15);

const _save = ValueKey('saveLog');
const _feed = ValueKey('feedField');
const _deaths = ValueKey('deathsField');
const _signs = ValueKey('optSigns');
const _colour = ValueKey('optColour');
const _feedings = ValueKey('optFeedings');
const _look = ValueKey('optDeathLook');

/// A daily-log test on the demo farm: a worker account unless [member],
/// the clock at [demoNow], a 360 × 780 phone, the log of [code] open.
void _logTest(
  String description,
  String code,
  Future<void> Function(WidgetTester tester, AppDatabase db, DemoFarm farm)
  body, {
  bool member = false,
}) => appTest(
  description,
  role: member ? MemberRole.member : MemberRole.worker,
  isAdmin: member,
  overrides: [clockProvider.overrideWithValue(() => demoNow)],
  (tester, db) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final farm = await seedDemoFarm(db);
    await tester.pumpAndSettle();
    appContainer(tester)
        .read(routerProvider)
        .push('/log/${farm[code]}${member ? '?lot=1' : ''}');
    await tester.pumpAndSettle();
    await body(tester, db, farm);
  },
);

Future<DailyLog> _saved(AppDatabase db, DemoFarm farm, String code) async {
  final session = (await SetupRepository(db).currentSession())!;
  return (await DailyLogRepository(db, session).forDay(farm[code]!, _day))!;
}

Future<void> _enter(WidgetTester tester, ValueKey<String> field, String text) =>
    tester.enterText(
      find.descendant(of: find.byKey(field), matching: find.byType(TextField)),
      text,
    );

Future<void> _pick(WidgetTester tester, Key option, List<Key> tiles) async {
  await tapAndSettle(tester, find.byKey(option));
  for (final t in tiles) {
    await tapAndSettle(tester, find.byKey(t));
  }
  await tapAndSettle(tester, find.text('Vita'));
}

double _bottom(WidgetTester tester, Finder f) => tester.getRect(f).bottom;

void main() {
  setUpAll(loadAppFonts);

  for (final code in ['E3', 'E2']) {
    _logTest('a normal day fits one screen, no scrolling ($code)', code, (
      tester,
      db,
      farm,
    ) async {
      final body = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('logBody')),
              matching: find.byType(Scrollable),
            )
            .first, // the page's own; its text fields have theirs
      );
      expect(body.position.maxScrollExtent, 0);
      for (final f in [
        find.byKey(_save),
        find.byKey(const ValueKey(Leftover.lots)),
        find.byKey(_deaths),
        find.byKey(_signs),
        find.byKey(_colour),
        find.byKey(_feedings),
      ]) {
        expect(_bottom(tester, f), lessThanOrEqualTo(780));
      }
    });
  }

  _logTest('all eaten adds "ate fast" and still fits', 'E3', (
    tester,
    db,
    farm,
  ) async {
    await tapAndSettle(tester, find.byKey(const ValueKey(Leftover.none)));
    expect(find.byKey(const ValueKey('ateFast')), findsOneWidget);
    expect(_bottom(tester, find.byKey(_feedings)), lessThanOrEqualTo(780));
  });

  _logTest('option titles never break a word (Malagasy)', 'E3', (
    tester,
    db,
    farm,
  ) async {
    for (final key in [_signs, _colour, _feedings]) {
      final title = find
          .descendant(of: find.byKey(key), matching: find.byType(Text))
          .first;
      final text = tester.widget<Text>(title).data!;
      final lines =
          tester.getSize(title).height /
          (DefaultTextStyle.of(tester.element(title)).style
                  .merge(tester.widget<Text>(title).style)
                  .fontSize! *
              1.5);
      // A single word never needs a second line.
      if (!text.contains(' ')) expect(lines, lessThan(1.5), reason: text);
    }
  });

  _logTest('a normal day in three actions', 'E3', (tester, db, farm) async {
    await _enter(tester, _feed, '4');
    await tapAndSettle(tester, find.byKey(const ValueKey(Leftover.some)));
    await tapAndSettle(tester, find.byKey(_save));
    final log = await _saved(db, farm, 'E3');
    expect(log.feedGivenG, 4000);
    expect(log.leftover, Leftover.some);
    expect(log.deaths, 0);
    expect(log.warningSigns, isEmpty);
    expect(log.waterColour, isNull);
    expect(log.feedings, isNull);
  });

  _logTest('signs come from their own screen; back keeps them', 'E3', (
    tester,
    db,
    farm,
  ) async {
    await _pick(tester, _signs, const [
      ValueKey(WarningSign.rubbing),
      ValueKey(WarningSign.whiteSpots),
    ]);
    Finder icons() =>
        find.descendant(of: find.byKey(_signs), matching: find.byType(Icon));
    expect(icons(), findsNWidgets(2));
    await tapAndSettle(tester, find.byKey(_signs));
    await tapAndSettle(
      tester,
      find.byKey(const ValueKey(WarningSign.nearBanks)),
    );
    await tapAndSettle(tester, find.byType(BackButton));
    expect(icons(), findsNWidgets(2));
    await _enter(tester, _feed, '4');
    await tapAndSettle(tester, find.byKey(_save));
    expect((await _saved(db, farm, 'E3')).warningSigns, {
      WarningSign.rubbing,
      WarningSign.whiteSpots,
    });
  });

  _logTest('water colour and feedings', 'E3', (tester, db, farm) async {
    await _pick(tester, _colour, const [ValueKey(WaterColour.mediumGreen)]);
    await _pick(tester, _feedings, const [ValueKey('feedings-3')]);
    expect(
      find.descendant(of: find.byKey(_feedings), matching: find.text('3')),
      findsOneWidget,
    );
    await _enter(tester, _feed, '4');
    await tapAndSettle(tester, find.byKey(_save));
    final log = await _saved(db, farm, 'E3');
    expect(log.waterColour, WaterColour.mediumGreen);
    expect(log.feedings, 3);
  });

  _logTest('what the dead looked like, only while there are deaths', 'E3', (
    tester,
    db,
    farm,
  ) async {
    expect(find.byKey(_look), findsNothing);
    await _enter(tester, _deaths, '2');
    await tester.pumpAndSettle();
    expect(find.byKey(_look), findsOneWidget);
    await _pick(tester, _look, [ValueKey(deathSigns.first)]);
    await _enter(tester, _deaths, '0');
    await tester.pumpAndSettle();
    expect(find.byKey(_look), findsNothing);
    await _enter(tester, _feed, '4');
    await tapAndSettle(tester, find.byKey(_save));
    expect((await _saved(db, farm, 'E3')).deathSigns, isEmpty);
  });

  _logTest('a worker meets no text field', 'E3', (tester, db, farm) async {
    expect(find.text('Fanamarihana'), findsNothing);
    expect(find.byKey(const ValueKey('feed-lot')), findsNothing);
  });

  _logTest('a member has the note and the lot', 'E3', member: true, (
    tester,
    db,
    farm,
  ) async {
    expect(find.text('Ajouter une note'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-lot')), findsOneWidget);
  });

  _logTest('the ration to aim for: feed bowl and plain kg', 'E3', (
    tester,
    db,
    farm,
  ) async {
    final ration = appContainer(tester)
        .read(pondOverviewsProvider)
        .value!
        .singleWhere((o) => o.pond.code == 'E3')
        .rationG;
    expect(find.byIcon(feedIcon), findsOneWidget);
    expect(find.text(formatKg(ration, const Locale('fr'))), findsOneWidget);
    expect(find.textContaining('≈'), findsNothing);
  });

  _logTest(
    'stop feeding: the sign instead of the ration; feed required',
    'E2',
    (tester, db, farm) async {
      expect(find.byType(StopFeedingSign), findsOneWidget);
      expect(find.byIcon(feedIcon), findsNothing);
      await tapAndSettle(tester, find.byKey(_save));
      expect(find.text('Ilaina'), findsOneWidget);
    },
  );

  _logTest('a logged day reopens and is corrected', 'E1', (
    tester,
    db,
    farm,
  ) async {
    final field = find.descendant(
      of: find.byKey(_feed),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(field).controller!.text, '7,4');
    await _enter(tester, _feed, '7');
    await tapAndSettle(tester, find.byKey(_save));
    // The correction supersedes the day's log; nothing is overwritten.
    expect((await _saved(db, farm, 'E1')).feedGivenG, 7000);
    final rows = [
      for (final l in await db.select(db.dailyLogs).get())
        if (l.pondId == farm['E1']) l,
    ];
    final first = rows.singleWhere((l) => l.feedGivenG == 7400);
    final fix = rows.singleWhere((l) => l.feedGivenG == 7000);
    expect(fix.supersedesId, first.id);
  });

  _logTest('with the keyboard open, Save stays within reach', 'E3', (
    tester,
    db,
    farm,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(_save).hitTestable(), findsOneWidget);
  });

  for (final (code, locale) in [('E1', 'mg'), ('E1', 'fr'), ('E2', 'mg')]) {
    _logTest('daily log golden $code $locale', code, (tester, db, farm) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold).last,
        matchesGoldenFile('goldens/log_${code}_$locale.png'),
      );
    });
  }
}
