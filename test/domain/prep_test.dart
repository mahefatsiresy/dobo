import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/domain/prep.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;
  DateTime day(int d) => DateTime(2026, 3, d);

  PrepStepFact step(PrepStep s, int on, {String pond = 'p1'}) =>
      PrepStepFact(id: '${s.name}$on', pondId: pond, step: s, date: day(on));

  PrepProgress progress(List<PrepStepFact> steps, {DateTime? lastWithFish}) =>
      prepProgress(
        pondId: 'p1',
        steps: steps,
        lastDayWithFish: lastWithFish,
        config: cfg,
      );

  test('no steps: next is drain, cannot mark ready', () {
    final p = progress(const []);
    expect((p.next, p.canMarkReady), (PrepStep.drain, false));
    expect(p.done, isEmpty);
  });

  test('drained on 1/3: dry from 6/3 to 8/3', () {
    final p = progress([step(PrepStep.drain, 1)]);
    expect((p.dryUntilMin, p.dryUntilMax), (day(6), day(8)));
    expect(p.next, PrepStep.dry);
  });

  test('filled on 10/3: rest until 12/3, can mark ready', () {
    final p = progress([
      step(PrepStep.drain, 1),
      step(PrepStep.dry, 7),
      step(PrepStep.treat, 8),
      step(PrepStep.fertilise, 9),
      step(PrepStep.fill, 10),
    ]);
    expect(
      (p.restUntil, p.canMarkReady, p.next),
      (day(12), true, PrepStep.rest),
    );
    expect(p.skipped, isEmpty);
  });

  test('fill without treat and fertilise lists them as skipped', () {
    final p = progress([
      step(PrepStep.drain, 1),
      step(PrepStep.dry, 7),
      step(PrepStep.fill, 10),
    ]);
    expect(p.skipped, [PrepStep.treat, PrepStep.fertilise]);
    expect(p.canMarkReady, true);
  });

  test('steps from before the pond last held fish are ignored', () {
    final p = progress([
      step(PrepStep.drain, 1),
      step(PrepStep.fill, 5),
      step(PrepStep.rest, 7),
      step(PrepStep.drain, 21),
    ], lastWithFish: day(20));
    expect(p.done.keys, [PrepStep.drain]);
    expect(p.done[PrepStep.drain]!.date, day(21));
    expect((p.restUntil, p.canMarkReady), (null, false));
  });

  test("another pond's steps are ignored", () {
    final p = progress([step(PrepStep.drain, 1, pond: 'p2')]);
    expect(p.done, isEmpty);
  });

  test('lastDayWithFish is the day before the pond emptied', () {
    final f = FarmFacts(
      stockings: [
        StockingFact(
          batchId: 'b1',
          pondId: 'p1',
          count: 100,
          avgWeightG: 20,
          date: day(1),
        ),
      ],
      harvests: [
        HarvestFact(
          batchId: 'b1',
          pondId: 'p1',
          count: 100,
          weightG: 25000,
          isFinal: true,
          date: day(15),
        ),
      ],
    );
    expect(lastDayWithFish(f, 'p1'), day(14));
    expect(lastDayWithFish(f, 'never'), isNull);
    expect(lastDayWithFish(const FarmFacts.empty(), 'p1'), isNull);
  });
}
