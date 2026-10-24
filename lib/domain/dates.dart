/// Madagascar (Indian/Antananarivo) is UTC+3 all year, with no daylight
/// saving, so a fixed offset gives its calendar day without a tz database.
const farmUtcOffset = Duration(hours: 3);

/// Whole calendar days from [from]'s date to [to]'s date, ignoring time of
/// day. Local times are taken as Madagascar wall-clock times; UTC times (as
/// Drift returns stored dates) are shifted by [farmUtcOffset], not by the
/// phone's zone, which may be set wrong.
int daysBetween(DateTime from, DateTime to) {
  DateTime day(DateTime t) {
    final farm = t.isUtc ? t.add(farmUtcOffset) : t;
    return DateTime.utc(farm.year, farm.month, farm.day);
  }

  return day(to).difference(day(from)).inDays;
}
