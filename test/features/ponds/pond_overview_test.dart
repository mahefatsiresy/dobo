import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/stock.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/ponds/pond_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures.dart';

void main() {
  const cfg = DomainConfig.defaults;
  final l1 = batchRow('L1'), l2 = batchRow('L2');
  final batches = {'L1': l1, 'L2': l2};

  test('figures for a stocked pond', () {
    final o = buildPondOverview(
      pondRow('E1', lengthM: 30, widthM: 15),
      [placementOf('L1', 'E1', 1000, 12.5), placementOf('L1', 'E2', 5, 12.5)],
      batches,
      cfg,
    );
    expect(
      (o.surfaceM2, o.liveCount, o.biomassG, o.inconsistent),
      (450.0, 1000, 12500, false),
    );
    expect(o.density, closeTo(2.22, 0.01));
    expect(o.densityStatus, DensityStatus.within);
    expect(o.batches.single.phase, Phase.pregrow);
    expect(o.batches.single.biomassG, 12500);
  });

  test('no surface: no density, no exception', () {
    final o = buildPondOverview(
      pondRow('E2'),
      [placementOf('L1', 'E2', 100, 12.5)],
      batches,
      cfg,
    );
    expect((o.density, o.densityStatus), (null, null));
  });

  test('an empty pond has no density status', () {
    final o = buildPondOverview(
      pondRow('E1', lengthM: 30, widthM: 15),
      const [],
      batches,
      cfg,
    );
    expect(
      (o.liveCount, o.biomassG, o.density, o.densityStatus),
      (0, 0, 0.0, null),
    );
    expect(o.batches, isEmpty);
  });

  test('an inconsistent placement shows as 0 and flags the pond', () {
    final o = buildPondOverview(
      pondRow('E1'),
      [placementOf('L1', 'E1', 0, 12.5, inconsistent: true)],
      batches,
      cfg,
    );
    expect((o.liveCount, o.inconsistent, o.batches.length), (0, true, 1));
  });

  test('a batch without a weight leaves biomass unknown', () {
    final o = buildPondOverview(
      pondRow('E1'),
      [placementOf('L1', 'E1', 100, 12.5), placementOf('L2', 'E1', 50, null)],
      batches,
      cfg,
    );
    expect((o.liveCount, o.biomassG), (150, null));
    expect(o.batches.last.phase, isNull);
  });

  test('two batches add up', () {
    final o = buildPondOverview(
      pondRow('E1', lengthM: 30, widthM: 15),
      [placementOf('L1', 'E1', 1000, 12.5), placementOf('L2', 'E1', 500, 30)],
      batches,
      cfg,
    );
    expect((o.liveCount, o.biomassG), (1500, 27500));
  });

  test('the overview carries the status the fish give', () {
    final stocked = buildPondOverview(
      pondRow('E1', status: PondStatus.empty),
      [placementOf('L1', 'E1', 100, 12.5)],
      batches,
      cfg,
    );
    final emptied = buildPondOverview(
      pondRow('E2', status: PondStatus.stocked),
      const [],
      batches,
      cfg,
    );
    expect(
      (stocked.status, emptied.status),
      (PondStatus.stocked, PondStatus.empty),
    );
  });
}
