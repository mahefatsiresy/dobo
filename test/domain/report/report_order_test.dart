import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/report/report_order.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime d(int day) => DateTime.utc(2026, 3, day, 9);
  const codes = {'e1': 'E1', 'e2': 'E2', 'e3': 'E3', 'e5': 'E5'};

  group('orderHealth', () {
    test('ponds with signs or events first, then by deaths, then code', () {
      final ordered = orderHealth([
        const PondHealth(pondId: 'e5', deaths: 500),
        PondHealth(
          pondId: 'e2',
          deaths: 1,
          signs: [
            DatedSigns(d(14), {WarningSign.surfaceSwimming}),
          ],
        ),
        const PondHealth(pondId: 'e1', deaths: 20),
      ], codes);
      expect([for (final h in ordered) h.pondId], ['e2', 'e5', 'e1']);
    });

    test('equal deaths and no signs go in code order', () {
      final ordered = orderHealth([
        const PondHealth(pondId: 'e3', deaths: 2),
        const PondHealth(pondId: 'e1', deaths: 2),
      ], codes);
      expect([for (final h in ordered) h.pondId], ['e1', 'e3']);
    });
  });

  test('a pond\'s lines: signs and events newest first, then treatments', () {
    final entries = healthEntries(
      PondHealth(
        pondId: 'e2',
        signs: [
          DatedSigns(d(14), {WarningSign.surfaceSwimming}),
        ],
        events: [HealthLine(at: d(13))],
        treatments: [TreatmentLine(at: d(15), product: 'X', dose: '5 g')],
      ),
    );
    expect(
      [for (final e in entries) (e.runtimeType, e.at.day)],
      [(SignsEntry, 14), (EventEntry, 13), (TreatmentEntry, 15)],
    );
  });

  group('splitObservations', () {
    ReportObservation answer(String? pond, ObservationCategory c, bool ok) =>
        ReportObservation(pondId: pond, category: c, ok: ok);
    const five = [
      ObservationCategory.dike,
      ObservationCategory.inletScreen,
      ObservationCategory.predatorNets,
      ObservationCategory.fence,
      ObservationCategory.grass,
    ];

    test('problems, then notes, then the ponds in order', () {
      final split = splitObservations([
        for (final c in five) answer('e3', c, true),
        answer('e1', ObservationCategory.dike, false),
        for (final c in five.skip(1)) answer('e1', c, true),
        const ReportObservation(
          category: ObservationCategory.fence,
          note: 'Clôture coupée',
        ),
        const ReportObservation(
          pondId: 'e2',
          category: ObservationCategory.other,
          note: 'Fuite',
        ),
      ], codes);
      expect(
        [for (final o in split.problems) (o.pondId, o.category)],
        [('e1', ObservationCategory.dike)],
      );
      expect(
        [for (final o in split.notes) o.note],
        ['Fuite', 'Clôture coupée'],
      );
      expect(split.inOrder, ['E3']);
    });

    test('an old report\'s OK answer without a pond shows nowhere', () {
      final split = splitObservations([
        answer(null, ObservationCategory.dike, true),
      ], codes);
      expect(split.problems, isEmpty);
      expect(split.notes, isEmpty);
      expect(split.inOrder, isEmpty);
    });
  });
}
