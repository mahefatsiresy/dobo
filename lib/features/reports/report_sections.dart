import 'package:flutter/material.dart';

import '../../domain/growth.dart';
import '../../domain/report/report_content.dart';
import '../../domain/types.dart';
import '../../domain/water.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';

/// The nine sections of a visit report (SPEC F8), drawn from its frozen
/// content. [summary] replaces the summary section (the draft's text field).
class ReportSections extends StatelessWidget {
  const ReportSections({super.key, required this.content, this.summary});

  final ReportContent content;
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(l10n.reportSummary),
        summary ??
            (c.summary == null
                ? _Empty(l10n.reportNoSummary)
                : Text(c.summary!)),
        _Heading(l10n.reportAlerts),
        if (c.alerts.isEmpty) _Empty(l10n.reportNothing),
        for (final a in c.alerts)
          _Line(
            icon: a.severity == Severity.danger ? Icons.error : Icons.warning,
            iconColor: a.severity == Severity.danger
                ? Colors.red.shade800
                : Colors.amber.shade800,
            pond: c.pondCodes[a.pondId],
            text: l10n.alertText(a, batchCode: c.batchCodes[a.batchId]),
          ),
        _Heading(l10n.reportHealth),
        if (c.health.isEmpty) _Empty(l10n.reportNothing),
        for (final h in c.health) _PondHealthBlock(content: c, health: h),
        _Heading(l10n.reportWater),
        if (c.water.isEmpty) _Empty(l10n.reportNoFish),
        for (final w in c.water) _WaterLine(content: c, water: w),
        _Heading(l10n.reportGrowth),
        if (c.growth.isEmpty) _Empty(l10n.reportNoFish),
        for (final g in c.growth) _GrowthBlock(content: c, growth: g),
        _Heading(l10n.reportFeed),
        if (c.feed.isEmpty) _Empty(l10n.reportNoFeed),
        for (final f in c.feed)
          _Line(
            pond: c.pondCodes[f.pondId],
            text: formatKg(f.feedG, Localizations.localeOf(context)),
          ),
        if (c.feed.isNotEmpty)
          _Line(
            text: l10n.labelValue(
              l10n.reportFeedTotal,
              formatKg(c.feedTotalG, Localizations.localeOf(context)),
            ),
          ),
        _Empty(l10n.reportFeedStockLater),
        _Heading(l10n.reportNext),
        if (c.next.isEmpty) _Empty(l10n.reportNothing),
        for (final n in c.next)
          _Line(
            pond: c.pondCodes[n.pondId],
            text: l10n.labelValue(
              formatDate(n.date),
              _nextText(l10n, n, c.batchCodes[n.batchId] ?? '?'),
            ),
          ),
        _Heading(l10n.reportObservations),
        ..._observations(context, c),
        const SizedBox(height: 24),
      ],
    );
  }

  static String _nextText(AppLocalizations l10n, NextItem n, String batch) =>
      switch (n.kind) {
        NextKind.sample => l10n.reportNextSample(batch),
        NextKind.harvest => l10n.reportNextHarvest(batch),
        NextKind.quarantineRelease => l10n.reportNextQuarantine(batch),
      };

  static List<Widget> _observations(BuildContext context, ReportContent c) {
    final l10n = AppLocalizations.of(context);
    final problems = [
      for (final o in c.observations)
        if (o.ok != true) o,
    ];
    final ok = [
      for (final o in c.observations)
        if (o.ok == true) o,
    ];
    return [
      if (problems.isEmpty && ok.isEmpty) _Empty(l10n.reportNothing),
      for (final o in problems)
        _Line(
          icon: o.ok == false ? Icons.report_problem : Icons.visibility,
          iconColor: o.ok == false ? Colors.amber.shade800 : null,
          pond: c.pondCodes[o.pondId],
          text: o.note == null
              ? l10n.observationCategory(o.category)
              : l10n.labelValue(l10n.observationCategory(o.category), o.note!),
        ),
      if (ok.isNotEmpty)
        _Line(
          icon: Icons.check_circle,
          iconColor: Colors.green.shade800,
          text: l10n.reportAllOk(
            {for (final o in ok) l10n.observationCategory(o.category)}
                .join(', '),
          ),
        ),
    ];
  }
}

class _PondHealthBlock extends StatelessWidget {
  const _PondHealthBlock({required this.content, required this.health});

  final ReportContent content;
  final PondHealth health;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final h = health;
    String actions(Set<HealthAction> a) => [
      for (final x in a)
        switch (x) {
          HealthAction.isolated => l10n.actionIsolated,
          HealthAction.technicianCalled => l10n.actionTechnician,
          HealthAction.released => l10n.actionReleased,
        },
    ].join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(
          pond: content.pondCodes[h.pondId],
          text: l10n.reportDeaths(formatCount(h.deaths, locale)),
        ),
        if (h.byObserver.isNotEmpty)
          _Indented(
            [
              for (final o in h.byObserver)
                l10n.reportObserverDeaths(
                  o.name ?? l10n.reportUnknownPerson,
                  formatCount(o.deaths, locale),
                ),
            ].join(l10n.reportListSeparator),
          ),
        for (final s in h.signs)
          _Indented(
            l10n.reportSigns(
              formatDate(s.date),
              s.signs.map(l10n.warningSign).join(', '),
            ),
          ),
        for (final e in h.events)
          _Indented(
            l10n.reportHealthEventLine(
              formatDate(e.at),
              [
                if (e.signs.isNotEmpty)
                  e.signs.map(l10n.warningSign).join(', '),
                ?e.suspectedIssue,
                if (e.actions.isNotEmpty) actions(e.actions),
              ].join(' — '),
            ),
          ),
        for (final t in h.treatments)
          _Indented(
            l10n.reportTreatmentLine(formatDate(t.at), t.product, t.dose),
          ),
      ],
    );
  }
}

class _WaterLine extends StatelessWidget {
  const _WaterLine({required this.content, required this.water});

  final ReportContent content;
  final PondWater water;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final w = water;
    final at = w.at;
    if (at == null) {
      return _Line(
        pond: content.pondCodes[w.pondId],
        text: l10n.reportNoReading,
      );
    }
    bool flagged(WaterParam p) => w.issues.any((i) => i.param == p);
    final danger = w.issues.any((i) => i.severity == Severity.danger);
    final values = [
      if (w.temperatureC != null)
        (
          WaterParam.temperature,
          l10n.labelValue(
            l10n.temperature,
            '${formatNumber(w.temperatureC!, locale)} °C',
          ),
        ),
      if (w.ph != null)
        (WaterParam.ph, l10n.labelValue(l10n.ph, formatNumber(w.ph!, locale))),
      if (w.oxygenMgL != null)
        (
          WaterParam.oxygen,
          l10n.labelValue(
            l10n.oxygen,
            '${formatNumber(w.oxygenMgL!, locale)} mg/L',
          ),
        ),
      if (w.colour != null) (WaterParam.colour, l10n.waterColour(w.colour!)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(
          icon: w.issues.isEmpty
              ? null
              : (danger ? Icons.error : Icons.warning),
          iconColor: danger ? Colors.red.shade800 : Colors.amber.shade800,
          pond: content.pondCodes[w.pondId],
          text: l10n.reportReadingOn(formatDate(at)),
        ),
        for (final (param, text) in values)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              text,
              style: flagged(param)
                  ? TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _GrowthBlock extends StatelessWidget {
  const _GrowthBlock({required this.content, required this.growth});

  final ReportContent content;
  final BatchGrowth growth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final g = growth;
    final fcr = switch (g.fcrNote) {
      FcrNote.shared => '— (${l10n.reportFcrShared})',
      FcrNote.noSample => '— (${l10n.reportFcrNoSample})',
      FcrNote.stalled => l10n.fcrStalled,
      null => formatDecimal(g.fcr!, locale, decimals: 2),
    };
    final trend = switch (g.trend) {
      FcrTrend.worse => ' (${l10n.reportTrendWorse})',
      FcrTrend.better => ' (${l10n.reportTrendBetter})',
      FcrTrend.same => ' (${l10n.reportTrendSame})',
      null => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(
          pond: content.pondCodes[g.pondId],
          text: l10n.reportGrowthLine(
            content.batchCodes[g.batchId] ?? '?',
            formatGrams(g.avgWeightG, locale),
            formatDate(g.weighedOn),
          ),
        ),
        _Estimated(
          l10n.labelValue(l10n.reportBiomass, formatKg(g.biomassG, locale)),
        ),
        _Estimated(
          l10n.labelValue(l10n.reportFish, formatCount(g.liveCount, locale)),
        ),
        _Indented(l10n.fcrValue('$fcr$trend')),
        if (g.survival != null)
          _Indented(
            l10n.survivalValue(
              formatDecimal(g.survival! * 100, locale, decimals: 0),
            ),
          ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(text, style: TextStyle(color: Theme.of(context).hintColor)),
  );
}

/// One report line: an optional icon, the pond's code, the text.
class _Line extends StatelessWidget {
  const _Line({required this.text, this.pond, this.icon, this.iconColor});

  final String text;
  final String? pond;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: pond == null
              ? null
              : Text(
                  pond!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 6),
        ],
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// An estimated figure, marked "estimé", wrapping on a narrow screen
/// (SPEC anti-goals: estimates never look exact).
class _Estimated extends StatelessWidget {
  const _Estimated(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 48, bottom: 2),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$text '),
          TextSpan(
            text: AppLocalizations.of(context).estimated,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
  );
}

class _Indented extends StatelessWidget {
  const _Indented(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 48, bottom: 2),
    child: Text(text),
  );
}
