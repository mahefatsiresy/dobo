import '../../domain/dates.dart';
import 'pond_growth.dart';

/// A batch's latest weight and, with two points or more, its change since
/// the previous point over how many days; null without any weight.
({double weightG, double? deltaG, int? days})? weightTrend(BatchGrowth g) {
  if (g.points.isEmpty) return null;
  final last = g.points.last;
  if (g.points.length == 1) {
    return (weightG: last.avgWeightG, deltaG: null, days: null);
  }
  final previous = g.points[g.points.length - 2];
  return (
    weightG: last.avgWeightG,
    deltaG: last.avgWeightG - previous.avgWeightG,
    days: daysBetween(previous.date, last.date),
  );
}

/// Deaths over the chart window: the total and the window's length in days.
({int deaths, int days}) deathsOverWindow(PondGrowth g) => (
  deaths: g.deathsPerDay.fold(0, (n, d) => n + d),
  days: g.deathsPerDay.length,
);

/// Health events and treatments together, by their dates: how many, and
/// the latest; null when there are none.
({int count, DateTime latest})? healthTally(List<DateTime> dates) {
  if (dates.isEmpty) return null;
  return (
    count: dates.length,
    latest: dates.reduce((a, b) => a.isAfter(b) ? a : b),
  );
}
