import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/report_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/db/repositories/visit_repository.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/reports/report_screen.dart';
import 'package:dobo/locale_controller.dart';
import 'package:dobo/router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../golden_fonts.dart';
import '../../helpers.dart';

DateTime _d(int day) => farmDateToUtc(DateTime(2026, 3, day));

ReportContent _content(int day, String member, {int dangers = 0}) =>
    ReportContent(
      header: ReportHeader(
        siteName: 'Ambohidratrimo',
        visitDay: _d(day),
        memberName: member,
        periodFrom: _d(day - 14),
        periodTo: _d(day),
        builtAt: _d(day),
      ),
      pondCodes: const {'e2': 'E2'},
      alerts: [
        for (var i = 0; i < dangers; i++)
          const Alert(AlertKind.growthStalled, Severity.danger, pondId: 'e2'),
      ],
    );

/// Two published reports from another phone (15/03 unread, with 2 dangers;
/// 01/03 read), and, unless [seed] is false, an unpublished draft of mine.
void _listTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  Size size = const Size(360, 780),
  bool seed = true,
}) => appTest(
  description,
  overrides: [clockProvider.overrideWithValue(() => demoNow)],
  (tester, db) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    if (seed) {
      final s = (await SetupRepository(db).currentSession())!;
      Future<String> report(ReportContent c, String visitId) async {
        final row = await db
            .into(db.visitReports)
            .insertReturning(
              VisitReportsCompanion.insert(
                associationId: s.associationId,
                enteredBy: 'someone-else',
                deviceId: 'other-phone',
                recordedAt: c.header.visitDay,
                visitId: visitId,
                siteId: s.siteId,
                periodFrom: c.header.periodFrom,
                periodTo: c.header.periodTo,
                content: c.encode(),
                syncState: const Value(SyncState.synced),
              ),
            );
        return row.id;
      }

      await report(_content(15, 'Rado', dangers: 2), 'v2');
      final read = await report(_content(1, 'Hery'), 'v1');
      await ReportRepository(db, s).markRead(read);
      final visits = VisitRepository(db, s);
      final v = await visits.start();
      await visits.end(v);
      await (db.update(db.visits)..where((x) => x.id.equals(v))).write(
        VisitsCompanion(startedAt: Value(demoNow), endedAt: Value(demoNow)),
      );
    }
    await tester.pumpAndSettle();
    appContainer(tester).read(routerProvider).go('/reports');
    await tester.pumpAndSettle();
    await body(tester, db);
  },
);

double _top(WidgetTester t, Finder f) => t.getTopLeft(f).dy;

void main() {
  setUpAll(loadAppFonts);

  _listTest('the draft first, then reports newest first', (tester, db) async {
    final draft = find.text('À publier : 15/03/2026');
    expect(draft, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: draft, matching: find.byType(InkWell)).first,
        matching: find.byIcon(Icons.edit),
      ),
      findsOneWidget,
    );
    final rado = find.text('15/03/2026, Rado');
    final hery = find.text('01/03/2026, Hery');
    expect(_top(tester, draft), lessThan(_top(tester, rado)));
    expect(_top(tester, rado), lessThan(_top(tester, hery)));
  });

  _listTest('unread: a dot and bold; dangers in words', (tester, db) async {
    final rado = find.text('15/03/2026, Rado');
    final hery = find.text('01/03/2026, Hery');
    expect(tester.widget<Text>(rado).style?.fontWeight, FontWeight.w700);
    expect(tester.widget<Text>(hery).style?.fontWeight, isNot(FontWeight.w700));
    expect(find.byKey(const ValueKey('unreadDot')), findsOneWidget);
    expect(find.text('2 en danger'), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  _listTest('a row opens its report', (tester, db) async {
    await tapAndSettle(tester, find.text('01/03/2026, Hery'));
    expect(find.byType(ReportScreen), findsOneWidget);
  });

  _listTest('no reports: what makes one', seed: false, (tester, db) async {
    expect(
      find.text("Aucun rapport. Le rapport se prépare à la fin d'une visite."),
      findsOneWidget,
    );
  });

  _listTest(
    'large text in Malagasy: nothing overflows',
    size: const Size(320, 1200),
    (tester, db) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(const Locale('mg'));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in ['fr', 'mg']) {
    _listTest('reports golden $locale', (tester, db) async {
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(locale));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold).last,
        matchesGoldenFile('goldens/reports_$locale.png'),
      );
    });
  }
}
