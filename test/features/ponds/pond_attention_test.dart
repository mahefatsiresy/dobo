import 'package:dobo/domain/alerts/alert.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/common/attention_band.dart';
import 'package:dobo/features/ponds/pond_attention.dart';
import 'package:dobo/features/ponds/pond_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures.dart';

PondOverview _overview({
  PondStatus status = PondStatus.stocked,
  bool inconsistent = false,
  int live = 100,
}) => PondOverview(
  pond: pondRow('p1'),
  status: status,
  surfaceM2: 500,
  batches: const [],
  liveCount: live,
  inconsistent: inconsistent,
  biomassG: null,
  density: null,
  densityStatus: null,
  rationG: 0,
);

const _oxygen = Alert(AlertKind.waterOutOfRange, Severity.danger, pondId: 'p1');
const _sample = Alert(AlertKind.sampleDue, Severity.warning, pondId: 'p1');

void main() {
  test('a stocked pond with no alerts gets no band', () {
    expect(pondAttention(_overview(), const []), isNull);
  });

  test('one warning alert leads a warning band', () {
    final a = pondAttention(_overview(), const [_sample])!;
    expect(a.severity, BandSeverity.warning);
    expect((a.lead as LeadAlert).alert, same(_sample));
    expect(a.more, 0);
  });

  test('alerts in compareAlerts order: the danger one leads', () {
    final a = pondAttention(_overview(), const [_oxygen, _sample])!;
    expect(a.severity, BandSeverity.danger);
    expect((a.lead as LeadAlert).alert, same(_oxygen));
    expect(a.more, 1);
  });

  test('isolated leads, ahead of its alerts', () {
    final a = pondAttention(_overview(status: PondStatus.isolated), const [
      _oxygen,
      _sample,
    ])!;
    expect(a.severity, BandSeverity.danger);
    expect(a.lead, isA<LeadIsolated>());
    expect(a.more, 2);
  });

  test('isolated and inconsistent with one alert: two more', () {
    final a = pondAttention(
      _overview(status: PondStatus.isolated, inconsistent: true),
      const [_sample],
    )!;
    expect(a.lead, isA<LeadIsolated>());
    expect(a.more, 2);
  });

  test('an inconsistent count alone is a danger band', () {
    final a = pondAttention(_overview(inconsistent: true), const [])!;
    expect(a.severity, BandSeverity.danger);
    expect(a.lead, isA<LeadInconsistent>());
    expect(a.more, 0);
  });

  test('an isolated pond with no fish still has its band', () {
    final a = pondAttention(
      _overview(status: PondStatus.isolated, live: 0),
      const [],
    )!;
    expect(a.severity, BandSeverity.danger);
    expect(a.lead, isA<LeadIsolated>());
    expect(a.more, 0);
  });
}
