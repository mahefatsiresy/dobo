import '../../db/database.dart';
import '../../domain/alerts/alert.dart';
import '../../domain/types.dart';
import '../ponds/pond_attention.dart';
import '../ponds/pond_overview.dart';

/// One row of the Alerts tab: a pond's item, or a farm-wide one.
class SectionItem {
  const SectionItem({required this.pond, required this.lead});

  /// Null for a farm-wide item (feed stock).
  final Pond? pond;
  final AttentionLead lead;
}

/// The Alerts tab's two sections (docs/design.md §Step 4): danger first,
/// then what is to do, each in pond code order with farm-wide items last.
({List<SectionItem> danger, List<SectionItem> todo}) alertSections(
  List<PondOverview> overviews,
  List<Alert> alerts,
) {
  final danger = <SectionItem>[];
  final todo = <SectionItem>[];
  final sorted = [...overviews]
    ..sort((a, b) => a.pond.code.compareTo(b.pond.code));
  for (final o in sorted) {
    final p = o.pond;
    if (o.status == PondStatus.isolated) {
      danger.add(SectionItem(pond: p, lead: const LeadIsolated()));
    }
    if (o.inconsistent) {
      danger.add(SectionItem(pond: p, lead: const LeadInconsistent()));
    }
    for (final a in alerts) {
      if (a.pondId != p.id) continue;
      (a.severity == Severity.danger ? danger : todo).add(
        SectionItem(pond: p, lead: LeadAlert(a)),
      );
    }
  }
  for (final a in alerts) {
    if (a.pondId != null) continue;
    (a.severity == Severity.danger ? danger : todo).add(
      SectionItem(pond: null, lead: LeadAlert(a)),
    );
  }
  return (danger: danger, todo: todo);
}
