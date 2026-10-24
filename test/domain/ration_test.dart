import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/ration.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;
  int r(Phase p, {int biomass = 100000, Leftover? left, bool fast = false}) =>
      suggestedRationG(
        biomassG: biomass,
        phase: p,
        lastLeftover: left,
        lastAteFast: fast,
        config: cfg,
      );

  test('base ration is biomass times the phase rate', () {
    expect(r(Phase.growout), 4000);
    expect(r(Phase.fry), 5000);
    expect(r(Phase.finishing), 3000);
    expect(r(Phase.growout, biomass: 0), 0);
  });

  test('leftovers cut the ration by 15 %', () {
    expect(r(Phase.growout, left: Leftover.some), 3400);
    expect(r(Phase.growout, left: Leftover.lots), 3400);
  });

  test('fast eating raises it by 5 %, capped at 5 % of biomass', () {
    expect(r(Phase.growout, fast: true), 4200);
    expect(r(Phase.fry, fast: true), 5000);
  });

  test('leftovers win over fast eating', () {
    expect(r(Phase.growout, left: Leftover.some, fast: true), 3400);
  });

  test('a pond\'s ration adds up its batches', () {
    expect(
      pondRationG(
        batches: [
          (biomassG: 100000, phase: Phase.growout),
          (biomassG: 50000, phase: Phase.fry),
        ],
        config: cfg,
      ),
      6500,
    );
    expect(
      pondRationG(
        batches: [(biomassG: 100000, phase: Phase.growout)],
        lastLeftover: Leftover.lots,
        config: cfg,
      ),
      3400,
    );
    expect(pondRationG(batches: const [], config: cfg), 0);
  });
}
