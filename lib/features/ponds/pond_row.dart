import 'package:flutter/material.dart';

import '../../domain/alerts/worker_advice.dart';
import '../../domain/prep.dart';
import '../../domain/stock.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../common/attention_band.dart';
import '../common/estimated.dart';
import '../common/pond_colour.dart';
import 'pond_attention.dart';
import 'pond_overview.dart';

/// The ration on a stocked pond's row, for tests.
const rationKey = ValueKey('pondRation');

/// The words of a pond row's band.
String bandText(AppLocalizations l10n, PondAttention a, PondOverview o) {
  final lead = switch (a.lead) {
    LeadIsolated() => l10n.pondIsolatedBanner,
    LeadInconsistent() => l10n.inconsistent,
    LeadAlert(:final alert) => l10n.alertText(
      alert,
      batchCode: [
        for (final b in o.batches)
          if (b.batch.id == alert.batchId) b.batch.code,
      ].firstOrNull,
    ),
  };
  return a.more == 0 ? lead : l10n.bandMore(lead, a.more);
}

/// A pond holding fish (docs/design.md §Step 1): the code, the band when it
/// needs someone, what's in it and whether today is logged, and today's
/// ration as the loudest number, or the stop-feeding sign.
class StockedPondRow extends StatelessWidget {
  const StockedPondRow({
    super.key,
    required this.overview,
    required this.attention,
    required this.loggedToday,
    required this.stopFeeding,
    required this.onTap,
  });

  final PondOverview overview;
  final PondAttention? attention;
  final bool loggedToday;
  final Set<StopFeedingReason> stopFeeding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final o = overview;
    final phases = {
      for (final b in o.batches)
        if (b.phase != null) l10n.phase(b.phase!),
    };
    final single = o.batches.length == 1 ? o.batches.single : null;
    final weight = single?.placement.avgWeightG;
    final density = o.densityStatus;

    final figures = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (phases.isNotEmpty) Text(phases.join(', '), style: text.titleMedium),
        EstimatedLabel(
          value: l10n.pondFishCount(formatCount(o.liveCount, locale)),
          style: text.bodyLarge,
        ),
        if (o.biomassG != null)
          EstimatedLabel(
            value: formatKg(o.biomassG!, locale),
            trailing: weight == null ? '' : ', ${formatGrams(weight, locale)}',
            style: text.bodyLarge,
          ),
        if (density != null && density != DensityStatus.within)
          Text(
            // The status names the density: "Densité trop forte : 7,2 /m²".
            l10n.labelValue(
              l10n.densityStatus(density),
              l10n.densityValue(formatDecimal(o.density!, locale)),
            ),
            // The density alert is a warning (DOMAIN §Alert rules).
            style: text.bodyMedium?.copyWith(color: c.warning),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              loggedToday ? Icons.task_alt : Icons.schedule,
              size: 18,
              color: loggedToday ? c.ok : c.inkMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                loggedToday ? l10n.pondLogDone : l10n.pondLogNotYet,
                style: text.bodySmall?.copyWith(
                  color: loggedToday ? c.ok : c.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final today = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (stopFeeding.isNotEmpty) ...[
          Icon(Icons.no_meals, color: c.danger, size: 32),
          Text(
            l10n.workerStopFeeding,
            textAlign: TextAlign.end,
            style: text.labelLarge?.copyWith(color: c.danger),
          ),
        ] else if (o.rationG > 0) ...[
          Text(
            l10n.rationToday,
            textAlign: TextAlign.end,
            style: text.bodySmall,
          ),
          // The loud number never splits from its unit: it shrinks instead.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: EstimatedLabel(
              key: rationKey,
              value: formatKg(o.rationG, locale),
              style: text.headlineSmall,
            ),
          ),
        ],
      ],
    );

    return _RowFrame(
      overview: o,
      attention: attention,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: figures),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 112),
              child: today,
            ),
          ],
        ),
      ),
    );
  }
}

/// A pond without fish: the code and one line of status, with the next
/// preparation step while it is being prepared.
class ShortPondRow extends StatelessWidget {
  const ShortPondRow({
    super.key,
    required this.overview,
    required this.attention,
    required this.prep,
    required this.onTap,
  });

  final PondOverview overview;
  final PondAttention? attention;
  final PrepProgress? prep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = l10n.pondStatus(overview.status);
    final next = prep?.next;
    return _RowFrame(
      overview: overview,
      attention: attention,
      onTap: onTap,
      child: Padding(
        // Top padding lines the status's first line up with the pond code.
        padding: const EdgeInsets.fromLTRB(12, 17, 12, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            overview.status == PondStatus.preparing && next != null
                ? l10n.pondPrepNext(status, l10n.prepStep(next))
                : status,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// The pond code down the left, beside the band and [child]: the band
/// belongs to its pond. One tap target, at least 56 dp tall.
class _RowFrame extends StatelessWidget {
  const _RowFrame({
    required this.overview,
    required this.attention,
    required this.onTap,
    required this.child,
  });

  final PondOverview overview;
  final PondAttention? attention;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final a = attention;
    final pond = overview.pond;
    return InkWell(
      key: ValueKey('pondRow-${pond.code}'),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              padding: const EdgeInsets.fromLTRB(12, 14, 4, 0),
              alignment: Alignment.topLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: PondCode(code: pond.code, colour: pond.colour),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (a != null)
                    AttentionBand(
                      severity: a.severity,
                      text: bandText(AppLocalizations.of(context), a, overview),
                    ),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
