import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/batches/stocking_warnings.dart';
import 'package:dobo/features/ponds/pond_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures.dart';

void main() {
  const cfg = DomainConfig.defaults;

  PondOverview overview({
    PondStatus status = PondStatus.ready,
    double? surface = 500,
    int live = 0,
    StructureType structure = StructureType.earth,
  }) => PondOverview(
    pond: pondRow('E1', status: status, structure: structure),
    status: status,
    surfaceM2: surface,
    batches: const [],
    liveCount: live,
    inconsistent: false,
    biomassG: 0,
    density: null,
    densityStatus: null,
    rationG: 0,
  );

  test('a ready pond at the right density and weight: no warning', () {
    expect(
      stockingWarnings(
        target: overview(),
        addedCount: 1500,
        avgWeightG: 15,
        config: cfg,
      ),
      isEmpty,
    );
  });

  test('a pond not marked ready', () {
    expect(
      stockingWarnings(
        target: overview(status: PondStatus.empty),
        addedCount: 1500,
        avgWeightG: 15,
        config: cfg,
      ),
      {StockingWarning.pondNotReady},
    );
  });

  test('too dense and too small', () {
    expect(
      stockingWarnings(
        target: overview(),
        addedCount: 4000,
        avgWeightG: 8,
        config: cfg,
      ),
      {StockingWarning.densityAbove, StockingWarning.weightOutsideRange},
    );
  });

  test('fish already in the pond count towards density', () {
    expect(
      stockingWarnings(
        target: overview(live: 2000),
        addedCount: 1500,
        avgWeightG: 15,
        config: cfg,
      ),
      {StockingWarning.densityAbove},
    );
  });

  test('too sparse', () {
    expect(
      stockingWarnings(
        target: overview(),
        addedCount: 500,
        avgWeightG: 15,
        config: cfg,
      ),
      {StockingWarning.densityBelow},
    );
  });

  test('an isolated pond with no surface', () {
    expect(
      stockingWarnings(
        target: overview(status: PondStatus.isolated, surface: null),
        addedCount: 10,
        config: cfg,
      ),
      {StockingWarning.pondIsolated},
    );
  });
}
