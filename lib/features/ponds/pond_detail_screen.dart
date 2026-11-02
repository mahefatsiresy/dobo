import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/errors.dart';
import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../../domain/phase.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../photos/photo_strip.dart';
import '../common/estimated.dart';
import '../common/notice.dart';
import '../common/pond_colour.dart';
import 'pond_figures.dart';
import 'pond_overview.dart';
import '../../domain/water.dart';
import '../readings/reading_providers.dart';
import '../health/health_providers.dart';
import '../../domain/fcr.dart';
import '../../domain/growth.dart';
import '../alerts/alert_providers.dart';
import '../alerts/alert_route.dart';
import '../alerts/alert_tile.dart';
import 'pond_charts.dart';
import 'pond_growth.dart';

class PondDetailScreen extends ConsumerWidget {
  const PondDetailScreen({super.key, required this.pondId});

  final String pondId;

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.archiveConfirm(code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.archive),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(pondRepositoryProvider).archive(pondId);
      if (context.mounted) context.go('/ponds');
    } on PondNotEmptyException {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.pondNotEmpty)));
      }
    }
  }

  Future<void> _release(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.releaseConfirm(code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.releaseIsolation),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(healthRepositoryProvider).release(pondId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final o = ref
        .watch(pondOverviewsProvider)
        .value
        ?.where((o) => o.pond.id == pondId)
        .firstOrNull;
    if (o == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pond = o.pond;
    final theme = Theme.of(context);
    final alerts = ref.watch(pondAlertsProvider(pond.id));
    final growth = ref.watch(pondGrowthProvider(pond.id));
    final batchCodes = {for (final b in o.batches) b.batch.id: b.batch.code};
    final wide = FilledButton.styleFrom(minimumSize: const Size.fromHeight(56));

    return Scaffold(
      appBar: AppBar(title: Text(pond.code)),
      // The isolation banner stays in view however far the page scrolls.
      bottomNavigationBar: o.status == PondStatus.isolated
          ? Material(
              color: Colors.red.shade50,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Notice(l10n.pondIsolatedBanner, danger: true),
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              PondBadge(code: pond.code, colour: pond.colour),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pondRole(pond.role),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(l10n.pondStatus(o.status)),
                    Text(
                      '${l10n.structure(pond.structure)}'
                      '${o.surfaceM2 == null ? '' : ' · ${formatNumber(o.surfaceM2!, locale)} m²'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final a in alerts)
            AlertTile(
              alert: a,
              pond: pond,
              batchCode: batchCodes[a.batchId],
              onTap: switch (alertRoute(a)) {
                final route? when route != '/ponds/${pond.id}' =>
                  () => context.push(route),
                _ => null,
              },
            ),
          const SizedBox(height: 16),
          PondFigures(overview: o),
          if (o.rationG > 0) ...[
            const SizedBox(height: 8),
            Text(l10n.rationToday, style: theme.textTheme.titleMedium),
            EstimatedLabel(
              value: formatKg(o.rationG, locale),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          _LatestReading(pondId: pond.id),
          for (final b in o.batches) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.batch.code, style: theme.textTheme.titleLarge),
                    if (b.phase != null) Text(l10n.phase(b.phase!)),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text(l10n.labelColon(l10n.pondFish)),
                        EstimatedLabel(
                          value: formatCount(b.placement.live.count, locale),
                        ),
                      ],
                    ),
                    if (b.placement.avgWeightG != null)
                      Text(
                        l10n.labelValue(
                          l10n.avgWeight,
                          formatGrams(b.placement.avgWeightG!, locale),
                        ),
                      ),
                    if (b.biomassG != null)
                      Wrap(
                        spacing: 8,
                        children: [
                          Text(l10n.labelColon(l10n.pondBiomass)),
                          EstimatedLabel(value: formatKg(b.biomassG!, locale)),
                        ],
                      ),
                    if (growth?.batches[b.batch.id] case final g?)
                      ..._growthLines(l10n, g, locale),
                    if (b.phase != null)
                      Text(
                        _feedingGuide(
                          l10n,
                          b.phase!,
                          locale,
                          ref.watch(domainConfigProvider),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: () => context.push(
                        '/transfer?batchId=${b.batch.id}&fromPondId=${pond.id}',
                      ),
                      icon: const Icon(Icons.swap_horiz),
                      label: Text(l10n.pondTransfer),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: () => context.push(
                        '/sample/${pond.id}?batchId=${b.batch.id}',
                      ),
                      icon: const Icon(Icons.scale),
                      label: Text(l10n.sampling),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (growth != null && o.batches.isNotEmpty) ...[
            const SizedBox(height: 24),
            PondCharts(growth: growth, batchCodes: batchCodes),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => context.push('/water/${pond.id}'),
            icon: const Icon(Icons.water_drop),
            label: Text(l10n.waterReading),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => context.push('/ponds/${pond.id}/problem'),
            icon: const Icon(Icons.report_problem),
            label: Text(l10n.reportProblem),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => context.push('/ponds/${pond.id}/treatment'),
            icon: const Icon(Icons.medication),
            label: Text(l10n.treatment),
          ),
          if (o.status == PondStatus.isolated) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () => _release(context, ref, pond.code),
              icon: const Icon(Icons.lock_open),
              label: Text(l10n.releaseIsolation),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            style: wide,
            onPressed: () => context.push('/log/${pond.id}'),
            icon: const Icon(Icons.edit_calendar),
            label: Text(l10n.dailyLog),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: wide,
            onPressed: () => context.push('/stock?pondId=${pond.id}'),
            icon: const Icon(Icons.add),
            label: Text(l10n.pondStock),
          ),
          if (ref.watch(sessionProvider).value?.isAdmin ?? false) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () => context.go('/ponds/${pond.id}/edit'),
              icon: const Icon(Icons.edit),
              label: Text(l10n.edit),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => _archive(context, ref, pond.code),
            icon: const Icon(Icons.archive),
            label: Text(l10n.archive),
          ),
          _HealthHistory(pondId: pond.id),
        ],
      ),
    );
  }

  /// Last weighing, period FCR with its trend, survival (SPEC F6).
  List<Widget> _growthLines(
    AppLocalizations l10n,
    BatchGrowth g,
    Locale locale,
  ) {
    final latest = g.periods.isEmpty ? null : g.periods.last.fcr;
    final (arrow, colour) = switch (g.trend) {
      FcrTrend.worse => (' ↑', Colors.red.shade800),
      FcrTrend.better => (' ↓', Colors.green.shade800),
      FcrTrend.same => (' →', null),
      null => ('', null),
    };
    return [
      Text(
        g.sampled
            ? l10n.lastWeighed('${g.daysSinceWeighing}')
            : l10n.notSampledYet('${g.daysSinceWeighing}'),
      ),
      if (g.periods.isNotEmpty)
        Text(
          l10n.fcrValue(switch (latest) {
            FcrValue(:final value) =>
              '${formatNumber((value * 100).round() / 100, locale)}$arrow',
            FcrStalled() => l10n.fcrStalled,
            null => '—',
          }),
          style: colour == null ? null : TextStyle(color: colour),
        ),
      if (g.survival != null)
        Text(
          l10n.survivalValue(
            formatDecimal(g.survival! * 100, locale, decimals: 0),
          ),
        ),
    ];
  }

  String _feedingGuide(
    AppLocalizations l10n,
    Phase phase,
    Locale locale,
    DomainConfig config,
  ) {
    final g = feedingGuideFor(phase, config);
    String n(num v) => formatNumber(v.toDouble(), locale);
    final protein = g.proteinPct == null
        ? l10n.adultFeed
        : '${n(g.proteinPct!.min)}–${n(g.proteinPct!.max)} %';
    final pellet = g.pelletMaxMm == null
        ? '≥ ${n(g.pelletMinMm)} mm'
        : g.pelletMaxMm == g.pelletMinMm
        ? '${n(g.pelletMinMm)} mm'
        : '${n(g.pelletMinMm)}–${n(g.pelletMaxMm!)} mm';
    final meals = '${g.feedingsPerDay.min} à ${g.feedingsPerDay.max}';
    return l10n.feedingGuide(protein, pellet, meals);
  }
}

/// The pond's latest water reading, values out of target in red.
class _LatestReading extends ConsumerWidget {
  const _LatestReading({required this.pondId});

  final String pondId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(latestReadingProvider(pondId)).value;
    if (r == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final issues = {
      for (final i in waterIssues(
        temperatureC: r.temperatureC,
        ph: r.ph,
        oxygenMgL: r.oxygenMgL,
        colour: r.colour,
        config: ref.watch(domainConfigProvider),
      ))
        i.param,
    };
    final red = TextStyle(color: Colors.red.shade800);
    String n(double v) => formatNumber(v, locale);
    Widget part(String text, WaterParam param) =>
        Text(text, style: issues.contains(param) ? red : null);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        children: [
          Text(l10n.lastReading(formatDate(r.recordedAt))),
          if (r.temperatureC != null)
            part('${n(r.temperatureC!)} °C', WaterParam.temperature),
          if (r.ph != null) part('pH ${n(r.ph!)}', WaterParam.ph),
          if (r.oxygenMgL != null)
            part('O₂ ${n(r.oxygenMgL!)} mg/L', WaterParam.oxygen),
          if (r.colour != null)
            part(l10n.waterColour(r.colour!), WaterParam.colour),
        ],
      ),
    );
  }
}

/// Health events and treatments of a pond, newest first (SPEC F9).
class _HealthHistory extends ConsumerWidget {
  const _HealthHistory({required this.pondId});

  final String pondId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(healthEventsProvider(pondId)).value ?? const [];
    final treatments = ref.watch(treatmentsProvider(pondId)).value ?? const [];
    if (events.isEmpty && treatments.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    String action(HealthAction a) => switch (a) {
      HealthAction.isolated => l10n.actionIsolated,
      HealthAction.technicianCalled => l10n.actionTechnician,
      HealthAction.released => l10n.actionReleased,
    };
    final lines = <(DateTime, String, String?)>[
      for (final e in events)
        (
          e.recordedAt,
          [
            formatDate(e.recordedAt),
            ...e.signs.map(l10n.warningSign),
            ?e.suspectedIssue,
            ...e.actions.map(action),
          ].join(' · '),
          e.id,
        ),
      for (final t in treatments)
        (
          t.recordedAt,
          '${formatDate(t.recordedAt)} · '
              '${l10n.labelValue(l10n.treatment, '${t.product}, ${t.dose}')}'
              '${t.advisedBy == null ? '' : ' (${t.advisedBy})'}',
          null,
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.healthHistory,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final (_, text, eventId) in lines) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(text),
            ),
            // Photos join a saved event, so the form is never lost to the
            // camera on a low-memory phone (SPEC §8).
            if (eventId != null)
              PhotoStrip(owner: PhotoOwner.healthEvent, ownerId: eventId),
          ],
        ],
      ),
    );
  }
}
