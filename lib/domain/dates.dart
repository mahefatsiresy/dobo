/// Whole calendar days from [from]'s date to [to]'s date, ignoring time of
/// day. Callers pass local (Indian/Antananarivo) times.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
