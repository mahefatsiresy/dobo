import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/providers.dart';
import '../../domain/alerts/alert.dart';
import '../../domain/config.dart';
import '../../domain/fcr.dart';
import '../../domain/growth.dart';
import '../../domain/phase.dart';
import '../../domain/stock.dart';
import '../../domain/types.dart';
import '../../domain/water.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../alerts/alert_providers.dart';
import '../alerts/alert_route.dart';
import '../common/action_tile.dart';
import '../common/attention_band.dart';
import '../common/estimated.dart';
import '../common/farm_today.dart';
import '../common/folded_section.dart';
import '../common/pond_colour.dart';
import '../daily_log/daily_log_providers.dart';
import '../health/health_providers.dart';
import '../photos/photo_strip.dart';
import '../prep/prep_providers.dart';
import '../readings/reading_providers.dart';
import 'pond_charts.dart';
import 'pond_growth.dart';
import 'pond_overview.dart';
import 'pond_row.dart';
import 'pond_summaries.dart';

/// A pond's page (docs/design.md §Step 2): what needs someone, today's
/// feed, what the pond holds, its water, folded trends and history, the
/// actions that apply, and the next thing to do pinned under the thumb.
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
    // Bands, the stop sign and the ration all come from the alerts: until
    // they are known the page would claim all is well (as on the list).
    final o = ref.watch(alertsProvider).hasValue
        ? ref
              .watch(pondOverviewsProvider)
              .value
              ?.where((o) => o.pond.id == pondId)
              .firstOrNull
        : null;
    if (o == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pond = o.pond;
    final id = pond.id;
    final hasFish = o.liveCount > 0 || o.inconsistent;
    final isolated = o.status == PondStatus.isolated;
    final isAdmin = ref.watch(sessionProvider).value?.isAdmin ?? false;
    final growth = hasFish ? ref.watch(pondGrowthProvider(id)) : null;
    final batchCodes = {for (final b in o.batches) b.batch.id: b.batch.code};

    // The next thing to do with this pond (docs/design.md §Step 2).
    final (barIcon, barLabel, barRoute) = hasFish
        ? (Icons.edit_calendar, l10n.dailyLog, '/log/$id?lot=1')
        : o.status == PondStatus.ready
        ? (Icons.add, l10n.pondStock, '/stock?pondId=$id')
        : (Icons.checklist, l10n.pondPrepare, '/ponds/$id/prep');

    final actions = <ActionTile>[
      ActionTile(
        icon: Icons.water_drop,
        label: l10n.waterReading,
        onTap: () => context.push('/water/$id'),
      ),
      ActionTile(
        icon: Icons.report_problem,
        label: l10n.reportProblem,
        onTap: () => context.push('/ponds/$id/problem'),
      ),
      ActionTile(
        icon: Icons.medication,
        label: l10n.treatment,
        onTap: () => context.push('/ponds/$id/treatment'),
      ),
      if (isolated)
        ActionTile(
          icon: Icons.lock_open,
          label: l10n.releaseIsolation,
          onTap: () => _release(context, ref, pond.code),
        ),
      if (!hasFish && barRoute != '/ponds/$id/prep')
        ActionTile(
          icon: Icons.checklist,
          label: l10n.prepButton,
          onTap: () => context.push('/ponds/$id/prep'),
        ),
      if (barRoute != '/stock?pondId=$id')
        ActionTile(
          icon: Icons.add,
          label: l10n.pondStock,
          onTap: () => context.push('/stock?pondId=$id'),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: PondCode(code: pond.code, colour: pond.colour),
        actions: [
          PopupMenuButton<void Function()>(
            tooltip: l10n.moreActions,
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              if (isAdmin)
                PopupMenuItem(
                  value: () => context.go('/ponds/$id/edit'),
                  child: Text(l10n.edit),
                ),
              PopupMenuItem(
                value: () => _archive(context, ref, pond.code),
                child: Text(l10n.archive),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => context.push(barRoute),
            icon: Icon(barIcon),
            label: Text(barLabel),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          ..._bands(context, l10n, o, ref.watch(pondAlertsProvider(id))),
          _Heading(overview: o, hasFish: hasFish),
          if (hasFish) _Today(overview: o),
          const Divider(),
          for (final b in o.batches) ...[
            _BatchBlock(
              pondId: id,
              batch: b,
              growth: growth?.batches[b.batch.id],
              showPhase: o.batches.length > 1,
            ),
            const Divider(),
          ],
          _LatestReading(pondId: id),
          if (growth != null && o.batches.isNotEmpty) ...[
            for (final kind in PondChartKind.values)
              FoldedSection(
                title: PondChart.title(l10n, kind),
                summary: _chartSummary(context, l10n, kind, growth, o),
                builder: (_) => PondChart(
                  kind: kind,
                  growth: growth,
                  batchCodes: batchCodes,
                ),
              ),
          ],
          _HealthSection(pondId: id),
          _PondFacts(overview: o),
          const Divider(),
          _ActionGrid(actions: actions),
        ],
      ),
    );
  }

  /// Every item that needs someone, most urgent first; an alert's band
  /// opens the screen that resolves it.
  List<Widget> _bands(
    BuildContext context,
    AppLocalizations l10n,
    PondOverview o,
    List<Alert> alerts,
  ) => [
    if (o.status == PondStatus.isolated)
      AttentionBand(
        severity: BandSeverity.danger,
        text: l10n.pondIsolatedBanner,
      ),
    if (o.inconsistent)
      AttentionBand(severity: BandSeverity.danger, text: l10n.inconsistent),
    for (final a in alerts)
      AttentionBand(
        severity: a.severity == Severity.danger
            ? BandSeverity.danger
            : BandSeverity.warning,
        text: l10n.alertText(
          a,
          batchCode: [
            for (final b in o.batches)
              if (b.batch.id == a.batchId) b.batch.code,
          ].firstOrNull,
        ),
        onTap: switch (alertRoute(a)) {
          final route? when route != '/ponds/$pondId' => () => context.push(
            route,
          ),
          _ => null,
        },
      ),
  ];

  String _chartSummary(
    BuildContext context,
    AppLocalizations l10n,
    PondChartKind kind,
    PondGrowth growth,
    PondOverview o,
  ) {
    final locale = Localizations.localeOf(context);
    String perBatch(String Function(BatchGrowth g) line) {
      final lines = [
        for (final b in o.batches)
          if (growth.batches[b.batch.id] case final g?)
            o.batches.length > 1 ? '${b.batch.code} : ${line(g)}' : line(g),
      ];
      return lines.join(', ');
    }

    return switch (kind) {
      PondChartKind.weight => perBatch((g) {
        final t = weightTrend(g);
        if (t == null) return '—';
        final weight = formatGrams(t.weightG, locale);
        if (t.deltaG == null) return weight;
        final delta = formatGrams(t.deltaG!.abs(), locale);
        return l10n.growthSummary(
          weight,
          '${t.deltaG! < 0 ? '−' : '+'}$delta',
          t.days!,
        );
      }),
      PondChartKind.deaths => () {
        final d = deathsOverWindow(growth);
        return l10n.deathsSummary(d.deaths, d.days);
      }(),
      PondChartKind.fcr => perBatch((g) => _fcrText(l10n, g, locale).$1),
    };
  }
}

/// A batch's latest period FCR with its trend arrow, and the colour of a
/// worsening or improving trend.
(String, Color?) _fcrText(
  AppLocalizations l10n,
  BatchGrowth g,
  Locale locale, [
  DoboColors? colours,
]) {
  final latest = g.periods.isEmpty ? null : g.periods.last.fcr;
  final (arrow, colour) = switch (g.trend) {
    FcrTrend.worse => (' ↑', colours?.danger),
    FcrTrend.better => (' ↓', colours?.ok),
    FcrTrend.same => (' →', null),
    null => ('', null),
  };
  return (
    switch (latest) {
      FcrValue(:final value) =>
        '${formatNumber((value * 100).round() / 100, locale)}$arrow',
      FcrStalled() => l10n.fcrStalled,
      null => '—',
    },
    colour,
  );
}

/// The phases the pond's fish are in; without fish, its status and the
/// next preparation step.
class _Heading extends ConsumerWidget {
  const _Heading({required this.overview, required this.hasFish});

  final PondOverview overview;
  final bool hasFish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final o = overview;
    final phases = {
      for (final b in o.batches)
        if (b.phase != null) l10n.phase(b.phase!),
    };
    final next = ref.watch(prepProgressAllProvider).value?[o.pond.id]?.next;
    final status = l10n.pondStatus(o.status);
    final text = hasFish
        ? phases.join(', ')
        : o.status == PondStatus.preparing && next != null
        ? l10n.pondPrepNext(status, l10n.prepStep(next))
        : status;
    if (text.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Whether today is logged and what was given, beside the suggested ration
/// or the stop-feeding sign.
class _Today extends ConsumerWidget {
  const _Today({required this.overview});

  final PondOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = overview.pond.id;
    final logged = ref.watch(loggedTodayProvider).value?.contains(id) ?? false;
    final log = logged
        ? ref
              .watch(dailyLogForDayProvider((id, ref.watch(farmTodayProvider))))
              .value
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LogStatus(logged: logged),
                if (log != null)
                  Text(
                    l10n.feedGivenToday(
                      formatKg(log.feedGivenG, Localizations.localeOf(context)),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: TodayFeed(
              rationG: overview.rationG,
              stopFeeding: ref.watch(stopFeedingProvider(id)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One batch in the pond: what it holds, how it grows, how to feed it, and
/// its own two actions.
class _BatchBlock extends ConsumerWidget {
  const _BatchBlock({
    required this.pondId,
    required this.batch,
    required this.growth,
    required this.showPhase,
  });

  final String pondId;
  final BatchInPond batch;
  final BatchGrowth? growth;
  final bool showPhase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final b = batch;
    final weight = b.placement.avgWeightG;
    final g = growth;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(b.batch.code, style: text.titleMedium),
          if (showPhase && b.phase != null) Text(l10n.phase(b.phase!)),
          EstimatedLabel(
            value: l10n.pondFishCount(
              formatCount(b.placement.live.count, locale),
            ),
            trailing: weight == null ? '' : ', ${formatGrams(weight, locale)}',
          ),
          if (b.biomassG != null)
            EstimatedLabel(value: formatKg(b.biomassG!, locale)),
          if (g != null) ...[
            Text(
              g.sampled
                  ? l10n.lastWeighed('${g.daysSinceWeighing}')
                  : l10n.notSampledYet('${g.daysSinceWeighing}'),
            ),
            if (g.periods.isNotEmpty)
              Builder(
                builder: (context) {
                  final (value, colour) = _fcrText(
                    l10n,
                    g,
                    locale,
                    context.dobo,
                  );
                  return Text(
                    l10n.fcrValue(value),
                    style: colour == null ? null : TextStyle(color: colour),
                  );
                },
              ),
            if (g.survival != null)
              Text(
                l10n.survivalValue(
                  formatDecimal(g.survival! * 100, locale, decimals: 0),
                ),
              ),
          ],
          if (b.phase != null)
            Text(
              _feedingGuide(
                l10n,
                b.phase!,
                locale,
                ref.watch(domainConfigProvider),
              ),
              style: text.bodySmall,
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ActionTile(
                  icon: Icons.scale,
                  label: l10n.weighAction,
                  onTap: () =>
                      context.push('/sample/$pondId?batchId=${b.batch.id}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActionTile(
                  icon: Icons.swap_horiz,
                  label: l10n.pondTransfer,
                  onTap: () => context.push(
                    '/transfer?batchId=${b.batch.id}&fromPondId=$pondId',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

/// The pond's latest water reading; a value out of target carries an icon
/// and its severity's colour (oxygen is danger, the rest warnings).
class _LatestReading extends ConsumerWidget {
  const _LatestReading({required this.pondId});

  final String pondId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(latestReadingProvider(pondId)).value;
    if (r == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final c = context.dobo;
    final issues = {
      for (final i in waterIssues(
        temperatureC: r.temperatureC,
        ph: r.ph,
        oxygenMgL: r.oxygenMgL,
        colour: r.colour,
        config: ref.watch(domainConfigProvider),
      ))
        i.param: i.severity,
    };
    String n(double v) => formatNumber(v, locale);
    Widget part(String text, WaterParam param) {
      final severity = issues[param];
      if (severity == null) return Text(text);
      final colour = severity == Severity.danger ? c.danger : c.warning;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            severity == Severity.danger ? Icons.error : Icons.warning_amber,
            size: 18,
            color: colour,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: colour, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
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
        ),
        const Divider(),
      ],
    );
  }
}

/// Health events and treatments, folded to a count and the latest date
/// (SPEC F9); nothing when there are none.
class _HealthSection extends ConsumerWidget {
  const _HealthSection({required this.pondId});

  final String pondId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(healthEventsProvider(pondId)).value ?? const [];
    final treatments = ref.watch(treatmentsProvider(pondId)).value ?? const [];
    final tally = healthTally([
      for (final e in events) e.recordedAt,
      for (final t in treatments) t.recordedAt,
    ]);
    if (tally == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return FoldedSection(
      title: l10n.healthHistory,
      summary: l10n.healthSummary(tally.count, formatDate(tally.latest)),
      builder: (context) =>
          _HealthHistory(events: events, treatments: treatments),
    );
  }
}

/// Health events and treatments of a pond, newest first, each event with
/// its photos.
class _HealthHistory extends StatelessWidget {
  const _HealthHistory({required this.events, required this.treatments});

  final List<HealthEvent> events;
  final List<Treatment> treatments;

  @override
  Widget build(BuildContext context) {
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
          ].join(', '),
          e.id,
        ),
      for (final t in treatments)
        (
          t.recordedAt,
          '${formatDate(t.recordedAt)}, '
              '${l10n.labelValue(l10n.treatment, '${t.product}, ${t.dose}')}'
              '${t.advisedBy == null ? '' : ' (${t.advisedBy})'}',
          null,
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}

/// The pond itself, folded: role, structure and surface; open, its depths
/// and density against the structure's range.
class _PondFacts extends StatelessWidget {
  const _PondFacts({required this.overview});

  final PondOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final o = overview;
    final pond = o.pond;
    String metres(double v) => '${formatNumber(v, locale)} m';
    return FoldedSection(
      title: l10n.pondFacts,
      summary: [
        l10n.pondRole(pond.role),
        l10n.structure(pond.structure),
        if (o.surfaceM2 != null) '${formatNumber(o.surfaceM2!, locale)} m²',
      ].join(', '),
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pond.depthInletM != null)
            Text(
              l10n.labelValue(l10n.pondDepthInlet, metres(pond.depthInletM!)),
            ),
          if (pond.depthOutletM != null)
            Text(
              l10n.labelValue(l10n.pondDepthOutlet, metres(pond.depthOutletM!)),
            ),
          if (o.density != null)
            Text(
              l10n.labelValue(
                o.densityStatus == null
                    ? l10n.pondDensity
                    : l10n.densityStatus(o.densityStatus!),
                l10n.densityValue(formatDecimal(o.density!, locale)),
              ),
              style:
                  o.densityStatus == null ||
                      o.densityStatus == DensityStatus.within
                  ? null
                  : TextStyle(color: context.dobo.warning),
            ),
        ],
      ),
    );
  }
}

/// The pond's other actions, two per row.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<ActionTile> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        for (var i = 0; i < actions.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: actions[i]),
                const SizedBox(width: 8),
                Expanded(
                  child: i + 1 < actions.length
                      ? actions[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
