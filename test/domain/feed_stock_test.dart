import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/feed_stock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;

  test('feed lot age thresholds', () {
    final made = DateTime(2026, 1, 1);
    FeedAge age(int days) => feedLotAge(
      manufacturedOn: made,
      today: made.add(Duration(days: days)),
      config: cfg,
    );
    expect(age(59), FeedAge.ok);
    expect(age(60), FeedAge.old);
    expect(age(90), FeedAge.expired);
  });

  test('days of stock left', () {
    expect(daysOfStockLeft(stockG: 70000, dailyUsageG: 10000), 7.0);
    expect(daysOfStockLeft(stockG: 70000, dailyUsageG: 0), isNull);
  });
}
