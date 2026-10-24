/// Madagascar (Indian/Antananarivo) is UTC+3 all year, with no daylight
/// saving, so a fixed offset gives its calendar day without a tz database.
const farmUtcOffset = Duration(hours: 3);

/// Madagascar wall-clock fields of [t]. Local times are taken as Madagascar
/// wall-clock times; UTC times (as Drift returns stored dates) are shifted by
/// [farmUtcOffset], not by the phone's zone, which may be set wrong.
DateTime _farmClock(DateTime t) => t.isUtc ? t.add(farmUtcOffset) : t;

/// Whole calendar days from [from]'s date to [to]'s date in Madagascar,
/// ignoring time of day.
int daysBetween(DateTime from, DateTime to) {
  DateTime day(DateTime t) {
    final farm = _farmClock(t);
    return DateTime.utc(farm.year, farm.month, farm.day);
  }

  return day(to).difference(day(from)).inDays;
}

/// The Madagascar calendar day of [t], as a date-only local `DateTime`.
DateTime farmDate(DateTime t) {
  final farm = _farmClock(t);
  return DateTime(farm.year, farm.month, farm.day);
}

/// A date entered by hand (its year, month and day fields), stored as 12:00
/// Madagascar time in UTC.
DateTime farmDateToUtc(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day, 12).subtract(farmUtcOffset);

/// A time read on the farm clock ([hour]:[minute] on [date]'s day), in UTC.
DateTime farmTimeToUtc(DateTime date, int hour, int minute) => DateTime.utc(
  date.year,
  date.month,
  date.day,
  hour,
  minute,
).subtract(farmUtcOffset);
