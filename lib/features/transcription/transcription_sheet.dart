import '../../db/repositories/daily_log_repository.dart';
import '../../domain/types.dart';
import '../../l10n/formatting.dart';

/// One day of a worker's paper sheet as typed, before it is saved
/// (docs/design.md §Step 7b).
class DayEntry {
  String kg = '';
  String deaths = '';
  Set<WarningSign> signs = {};
  Leftover? leftover;
  bool ateFast = false;
  WaterColour? colour;

  /// Leftovers, signs or the water colour were picked.
  bool get hasDetails =>
      signs.isNotEmpty || leftover != null || ateFast || colour != null;

  bool get isEmpty => kg.trim().isEmpty && deaths.trim().isEmpty && !hasDetails;
}

/// What saving the sheet of [pondId] sends: one log per typed day, seen by
/// [personId]. A day with anything typed but no feed is listed in
/// `missingFeed`, and then nothing is sent. Days already logged are never
/// in [typed].
({List<DailyLogInput> inputs, List<DateTime> missingFeed}) sheetInputs({
  required String pondId,
  required String personId,
  required Map<DateTime, DayEntry> typed,
}) {
  final days = typed.keys.where((d) => !typed[d]!.isEmpty).toList()..sort();
  final missing = [
    for (final d in days)
      if (parseDecimal(typed[d]!.kg) == null) d,
  ];
  if (missing.isNotEmpty) return (inputs: const [], missingFeed: missing);
  return (
    inputs: [
      for (final d in days)
        DailyLogInput(
          pondId: pondId,
          date: d,
          feedGivenG: (parseDecimal(typed[d]!.kg)! * 1000).round(),
          deaths: parseDecimal(typed[d]!.deaths)?.round() ?? 0,
          warningSigns: typed[d]!.signs,
          leftover: typed[d]!.leftover,
          ateFast: typed[d]!.ateFast,
          waterColour: typed[d]!.colour,
          observedBy: personId,
        ),
    ],
    missingFeed: const [],
  );
}
