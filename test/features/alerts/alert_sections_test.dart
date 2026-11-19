import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/alerts/alert_providers.dart';
import 'package:dobo/features/alerts/alert_sections.dart';
import 'package:dobo/features/common/farm_today.dart';
import 'package:dobo/features/ponds/pond_attention.dart';
import 'package:dobo/features/ponds/pond_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../demo_farm.dart';
import '../../fixtures.dart';
import '../../helpers.dart';

PondOverview _o(
  String id, {
  PondStatus status = PondStatus.stocked,
  bool inconsistent = false,
}) => PondOverview(
  pond: pondRow(id, code: id.toUpperCase()),
  status: status,
  surfaceM2: 500,
  batches: const [],
  liveCount: 100,
  inconsistent: inconsistent,
  biomassG: null,
  density: null,
  densityStatus: null,
  rationG: 0,
);

Alert _a(AlertKind k, Severity s, [String? pond]) => Alert(k, s, pondId: pond);

String _describe(SectionItem i) =>
    '${i.pond?.code ?? '-'}:${switch (i.lead) {
      LeadIsolated() => 'isolated',
      LeadInconsistent() => 'inconsistent',
      LeadAlert(:final alert) => alert.kind.name,
    }}';

void main() {
  test('an isolated pond is danger; its warning is to do', () {
    final s = alertSections(
      [_o('e4', status: PondStatus.isolated)],
      [_a(AlertKind.waterCheckDue, Severity.warning, 'e4')],
    );
    expect(s.danger.map(_describe), ['E4:isolated']);
    expect(s.todo.map(_describe), ['E4:waterCheckDue']);
  });

  test('inconsistent comes before the same pond\'s danger alert', () {
    final s = alertSections(
      [_o('e5', inconsistent: true)],
      [_a(AlertKind.mortalitySpike, Severity.danger, 'e5')],
    );
    expect(s.danger.map(_describe), ['E5:inconsistent', 'E5:mortalitySpike']);
  });

  test('ponds in code order, even when alerts come in another order', () {
    final s = alertSections(
      [_o('e2'), _o('e3')],
      [
        _a(AlertKind.sampleDue, Severity.warning, 'e3'),
        _a(AlertKind.sampleDue, Severity.warning, 'e2'),
      ],
    );
    expect(s.todo.map(_describe), ['E2:sampleDue', 'E3:sampleDue']);
  });

  test('farm-wide items come last in their section, with no pond', () {
    final s = alertSections(
      [_o('e2')],
      [
        _a(AlertKind.feedTooOld, Severity.danger),
        _a(AlertKind.waterOutOfRange, Severity.danger, 'e2'),
        _a(AlertKind.feedStockLow, Severity.warning),
      ],
    );
    expect(s.danger.map(_describe), ['E2:waterOutOfRange', '-:feedTooOld']);
    expect(s.todo.map(_describe), ['-:feedStockLow']);
  });

  test('an alert for a pond not shown is left out', () {
    final s = alertSections(
      [_o('e2')],
      [_a(AlertKind.sampleDue, Severity.warning, 'gone')],
    );
    expect(s.todo, isEmpty);
  });

  appTest(
    'demo farm: three ponds in danger, the badge says so',
    overrides: [clockProvider.overrideWithValue(() => demoNow)],
    (tester, db) async {
      await seedDemoFarm(db);
      await tester.pumpAndSettle();
      expect(appContainer(tester).read(dangerPondsProvider), (
        ponds: 3,
        farmWide: 0,
      ));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('alertsBadge')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
    },
  );
}
