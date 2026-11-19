import '../alerts/alert.dart';
import 'report_content.dart';

/// The order a report's health and observation sections are read in, the
/// same on screen and in the PDF (docs/design.md §Step 6).

/// Ponds with warning signs or health events first, then by deaths
/// (highest first), then by pond code.
List<PondHealth> orderHealth(
  List<PondHealth> health,
  Map<String, String> pondCodes,
) {
  bool alarmed(PondHealth h) => h.signs.isNotEmpty || h.events.isNotEmpty;
  return [...health]..sort((a, b) {
    if (alarmed(a) != alarmed(b)) return alarmed(a) ? -1 : 1;
    final byDeaths = b.deaths.compareTo(a.deaths);
    if (byDeaths != 0) return byDeaths;
    return (pondCodes[a.pondId] ?? '').compareTo(pondCodes[b.pondId] ?? '');
  });
}

/// One line under a pond's deaths in the health section.
sealed class HealthEntry {
  const HealthEntry();

  DateTime get at;
}

final class SignsEntry extends HealthEntry {
  const SignsEntry(this.signs);

  final DatedSigns signs;

  @override
  DateTime get at => signs.date;
}

final class EventEntry extends HealthEntry {
  const EventEntry(this.event);

  final HealthLine event;

  @override
  DateTime get at => event.at;
}

final class TreatmentEntry extends HealthEntry {
  const TreatmentEntry(this.treatment);

  final TreatmentLine treatment;

  @override
  DateTime get at => treatment.at;
}

/// A pond's health lines: signs and events, newest first, then treatments,
/// newest first.
List<HealthEntry> healthEntries(PondHealth h) {
  int newest(HealthEntry a, HealthEntry b) => b.at.compareTo(a.at);
  return [
    ...[
      for (final s in h.signs) SignsEntry(s),
      for (final e in h.events) EventEntry(e),
    ]..sort(newest),
    ...[for (final t in h.treatments) TreatmentEntry(t)]..sort(newest),
  ];
}

/// A report's observations: problems found, free notes (farm-wide last),
/// and the codes of the ponds inspected with everything in order.
({
  List<ReportObservation> problems,
  List<ReportObservation> notes,
  List<String> inOrder,
})
splitObservations(
  List<ReportObservation> observations,
  Map<String, String> pondCodes,
) {
  // Farm-wide (no pond) sorts after every pond.
  String key(ReportObservation o) =>
      o.pondId == null ? '\u{10FFFF}' : (pondCodes[o.pondId] ?? '');
  int byPond(ReportObservation a, ReportObservation b) =>
      key(a).compareTo(key(b));
  final problems = [
    for (final o in observations)
      if (o.ok == false) o,
  ]..sort(byPond);
  final notes = [
    for (final o in observations)
      if (o.ok == null) o,
  ]..sort(byPond);
  final withProblem = {for (final o in problems) o.pondId};
  final inOrder = {
    for (final o in observations)
      if (o.ok == true &&
          o.pondId != null &&
          !withProblem.contains(o.pondId) &&
          pondCodes[o.pondId] != null)
        pondCodes[o.pondId]!,
  }.toList()..sort();
  return (problems: problems, notes: notes, inOrder: inOrder);
}
