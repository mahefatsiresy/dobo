/// Whole calendar days from [from]'s date to [to]'s date, ignoring time of
/// day. Local times are used as given; UTC times (as Drift returns stored
/// dates) are converted to the device's local zone first.
int daysBetween(DateTime from, DateTime to) {
  DateTime day(DateTime t) {
    final local = t.isUtc ? t.toLocal() : t;
    return DateTime.utc(local.year, local.month, local.day);
  }

  return day(to).difference(day(from)).inDays;
}
