import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../alerts/alert_providers.dart';
import '../alerts/alert_route.dart';
import '../common/attention_band.dart';
import '../common/pond_colour.dart';
import '../photos/photo_strip.dart';
import '../ponds/pond_attention.dart';
import '../ponds/pond_row.dart';
import '../readings/reading_values.dart';
import 'visit_checklist.dart';

/// The width of the pond code column; checks line up after it.
const _codeColumn = 72.0;

/// One pond during a visit (docs/design.md §Step 5): a header that opens
/// the pond, its band opening its fix, its checks (each done with what it
/// found, or to do), then the observations about it.
class VisitPondGroup extends ConsumerWidget {
  const VisitPondGroup({super.key, required this.visit});

  final PondVisit visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final o = visit.overview;
    final pond = o.pond;
    final attention = pondAttention(o, ref.watch(pondAlertsProvider(pond.id)));
    final phases = {
      for (final b in o.batches)
        if (b.phase != null) l10n.phase(b.phase!),
    };
    final hasFish = o.liveCount > 0 || o.inconsistent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: ValueKey('visitPond-${pond.code}'),
          onTap: () => context.push('/ponds/${pond.id}'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                Container(
                  width: _codeColumn,
                  padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: PondCode(code: pond.code, colour: pond.colour),
                  ),
                ),
                Expanded(
                  child: Text(
                    hasFish && phases.isNotEmpty
                        ? phases.join(', ')
                        : l10n.pondStatus(o.status),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
        if (attention != null)
          KeyedSubtree(
            key: ValueKey('visitBand-${pond.code}'),
            child: AttentionBand(
              severity: attention.severity,
              text: bandText(l10n, attention, o),
              onTap: () => context.push(switch (attention.lead) {
                LeadAlert(:final alert) =>
                  alertRoute(alert) ?? '/ponds/${pond.id}',
                _ => '/ponds/${pond.id}',
              }),
            ),
          ),
        for (final check in visit.checks) _checkRow(context, l10n, check),
        for (final n in visit.observations) ObservationLine(observation: n),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _checkRow(
    BuildContext context,
    AppLocalizations l10n,
    VisitCheck check,
  ) {
    final pond = visit.overview.pond;
    final locale = Localizations.localeOf(context);
    final c = context.dobo;
    return switch (check) {
      WaterCheck(:final reading) => CheckRow(
        key: ValueKey('water-${pond.code}'),
        done: check.done,
        icon: Icons.water_drop,
        title: l10n.waterReading,
        result: reading == null ? null : ReadingValues(reading: reading),
        onTap: () => context.push(
          reading == null
              ? '/water/${pond.id}'
              : '/water/${pond.id}?readingId=${reading.id}',
        ),
      ),
      SampleCheck(:final batch, :final sample) => CheckRow(
        key: ValueKey('sample-${batch.code}-${pond.code}'),
        done: check.done,
        icon: Icons.scale,
        title: l10n.sampling,
        result: Text(
          sample == null
              ? batch.code
              : l10n.visitSampleDone(
                  batch.code,
                  formatGrams(sample.totalWeightG / sample.fishCount, locale),
                  sample.fishCount,
                ),
        ),
        onTap: () => context.push(
          '/sample/${pond.id}?batchId=${batch.id}'
          '${sample == null ? '' : '&sampleId=${sample.id}'}',
        ),
      ),
      InspectionCheck() => CheckRow(
        key: ValueKey('conditions-${pond.code}'),
        done: check.done,
        icon: Icons.fact_check,
        title: l10n.visitInspection,
        result: !check.done
            ? null
            : check.problems.isEmpty
            ? Text(l10n.visitAllInOrder)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error, size: 18, color: c.danger),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l10n.visitProblems(
                        check.problems.length,
                        check.problems.map(l10n.observationCategory).join(', '),
                      ),
                      style: TextStyle(
                        color: c.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
        onTap: () => context.push('/visit/conditions/${pond.id}'),
      ),
    };
  }
}

/// One check of a visit: its icon (a tick once done), its name and what
/// it found; a 56 dp row that opens its form.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.done,
    required this.icon,
    required this.title,
    required this.onTap,
    this.result,
  });

  final bool done;
  final IconData icon;
  final String title;
  final Widget? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dobo;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_codeColumn - 36, 8, 12, 8),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : icon,
                color: done ? c.ok : c.ink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge),
                    if (result != null)
                      DefaultTextStyle.merge(
                        style: Theme.of(context).textTheme.bodyMedium,
                        child: result!,
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// A free observation: its category, its note and its photos.
class ObservationLine extends StatelessWidget {
  const ObservationLine({super.key, required this.observation});

  final Observation observation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final o = observation;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_codeColumn - 36, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.observationCategory(o.category),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (o.note != null) Text(o.note!),
                PhotoStrip(owner: PhotoOwner.observation, ownerId: o.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
