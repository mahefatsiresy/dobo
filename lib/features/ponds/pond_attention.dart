import '../../domain/alerts/alert.dart';
import '../../domain/types.dart';
import '../common/attention_band.dart';
import 'pond_overview.dart';

/// What a pond row's band names.
sealed class AttentionLead {
  const AttentionLead();
}

final class LeadIsolated extends AttentionLead {
  const LeadIsolated();
}

final class LeadInconsistent extends AttentionLead {
  const LeadInconsistent();
}

final class LeadAlert extends AttentionLead {
  const LeadAlert(this.alert);

  final Alert alert;
}

/// The one band a pond row shows: its most urgent item and how many others.
class PondAttention {
  const PondAttention({
    required this.severity,
    required this.lead,
    required this.more,
  });

  final BandSeverity severity;
  final AttentionLead lead;

  /// Other items besides the lead.
  final int more;
}

/// The band of a pond with [alerts] (already in `compareAlerts` order,
/// danger first); null when the pond needs nothing. An isolated pond comes
/// first, then a count that doesn't add up, then the alerts.
PondAttention? pondAttention(PondOverview overview, List<Alert> alerts) {
  final items = <(AttentionLead, BandSeverity)>[
    if (overview.status == PondStatus.isolated)
      (const LeadIsolated(), BandSeverity.danger),
    if (overview.inconsistent) (const LeadInconsistent(), BandSeverity.danger),
    for (final a in alerts)
      (
        LeadAlert(a),
        a.severity == Severity.danger
            ? BandSeverity.danger
            : BandSeverity.warning,
      ),
  ];
  if (items.isEmpty) return null;
  final (lead, severity) = items.first;
  return PondAttention(severity: severity, lead: lead, more: items.length - 1);
}
