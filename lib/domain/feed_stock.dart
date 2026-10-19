import 'config.dart';
import 'dates.dart';

enum FeedAge { ok, old, expired }

/// DOMAIN §Feed stock.
FeedAge feedLotAge({
  required DateTime manufacturedOn,
  required DateTime today,
  required DomainConfig config,
}) {
  final days = daysBetween(manufacturedOn, today);
  if (days >= config.feedAgeDangerDays) return FeedAge.expired;
  if (days >= config.feedAgeWarnDays) return FeedAge.old;
  return FeedAge.ok;
}

double? daysOfStockLeft({required int stockG, required int dailyUsageG}) =>
    dailyUsageG <= 0 ? null : stockG / dailyUsageG;
