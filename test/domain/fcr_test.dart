import 'package:dobo/domain/fcr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  double v(FcrResult r) => (r as FcrValue).value;
  List<FcrResult> f(List<double> xs) => [for (final x in xs) FcrValue(x)];

  group('periodFcr', () {
    test('feed over weight gained, counting fish moved in and out', () {
      expect(
        v(periodFcr(feedG: 30000, biomassPrevG: 50000, biomassNowG: 70000)),
        1.5,
      );
      expect(
        v(
          periodFcr(
            feedG: 30000,
            biomassPrevG: 50000,
            biomassNowG: 50000,
            outWeightG: 20000,
          ),
        ),
        1.5,
      );
      expect(
        v(
          periodFcr(
            feedG: 30000,
            biomassPrevG: 50000,
            biomassNowG: 80000,
            inWeightG: 10000,
          ),
        ),
        1.5,
      );
      expect(
        v(periodFcr(feedG: 0, biomassPrevG: 50000, biomassNowG: 60000)),
        0.0,
      );
    });

    test('no gain means growth stalled', () {
      expect(
        periodFcr(feedG: 30000, biomassPrevG: 50000, biomassNowG: 50000),
        isA<FcrStalled>(),
      );
      expect(
        periodFcr(feedG: 30000, biomassPrevG: 50000, biomassNowG: 45000),
        isA<FcrStalled>(),
      );
    });
  });

  test('cycleFcr', () {
    expect(
      v(cycleFcr(totalFeedG: 450000, harvestedG: 320000, stockedG: 20000)),
      1.5,
    );
    expect(
      cycleFcr(totalFeedG: 1000, harvestedG: 0, stockedG: 20000),
      isA<FcrStalled>(),
    );
  });

  group('isFcrWorsening', () {
    test('true when the last three strictly increase', () {
      expect(isFcrWorsening(f([1.5, 1.6, 1.7])), isTrue);
      expect(isFcrWorsening(f([2.0, 1.5, 1.6, 1.7])), isTrue);
    });

    test('false otherwise', () {
      expect(isFcrWorsening(f([1.5, 1.7, 1.6])), isFalse);
      expect(isFcrWorsening(f([1.4, 1.5, 1.6, 1.5])), isFalse);
      expect(isFcrWorsening(f([1.6, 1.7])), isFalse);
      expect(isFcrWorsening(f([1.5, 1.5, 1.6])), isFalse);
      expect(
        isFcrWorsening([
          const FcrValue(1.5),
          const FcrStalled(),
          const FcrValue(1.8),
        ]),
        isFalse,
      );
    });
  });
}
