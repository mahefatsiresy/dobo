/// Monday to Sunday of the week holding [farmDay], as date-only values.
/// Built from day numbers, so no zone's daylight saving can shift a day.
List<DateTime> weekOf(DateTime farmDay) {
  final monday = farmDay.day - (farmDay.weekday - DateTime.monday);
  return [
    for (var i = 0; i < 7; i++)
      DateTime(farmDay.year, farmDay.month, monday + i),
  ];
}
