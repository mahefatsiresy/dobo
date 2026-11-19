import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/growth.dart';
import '../../domain/report/report_content.dart';
import '../../domain/report/report_order.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../common/attention_band.dart';
import '../common/coded_band.dart';
import '../common/estimated.dart';
import '../common/pond_colour.dart';
import '../photos/photo_strip.dart';
import '../ponds/pond_overview.dart';
import '../readings/reading_values.dart';

/// The width of the pond code column; lines under a pond start after it.
const _codeColumn = 72.0;

/// The sections of a visit report (SPEC F8, docs/design.md §Step 6), by
/// topic and in F8's order, drawn from its frozen content. [summary]
/// replaces the summary text (the draft's box); [visitPhotos] the visit's
/// photos (the draft's editable strip).
class ReportSections extends ConsumerWidget {
  const ReportSections({
    super.key,
    required this.content,
    this.summary,
    this.visitPhotos,
  });

  final ReportContent content;
  final Widget? summary;
  final Widget? visitPhotos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final c = content;
    final colours = ref.watch(pondColoursProvider);
    Widget pond(String? pondId, Widget child, {IconData? icon, Color? ic}) =>
        _PondLine(
          code: c.pondCodes[pondId],
          colour: colours[pondId],
          icon: icon,
          iconColour: ic,
          child: child,
        );
    final split = splitObservations(c.observations, c.pondCodes);
    final growth = [...c.growth]
      ..sort((a, b) {
        final byPond = (c.pondCodes[a.pondId] ?? '').compareTo(
          c.pondCodes[b.pondId] ?? '',
        );
        return byPond != 0
            ? byPond
            : (c.batchCodes[a.batchId] ?? '').compareTo(
                c.batchCodes[b.batchId] ?? '',
              );
      });
    final water = [...c.water]
      ..sort(
        (a, b) => (c.pondCodes[a.pondId] ?? '').compareTo(
          c.pondCodes[b.pondId] ?? '',
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(l10n.reportSummary),
        summary ??
            (c.summary == null
                ? _Empty(l10n.reportNoSummary)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      c.summary!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )),

        _Heading(l10n.reportAlerts),
        if (c.alerts.isEmpty) _Empty(l10n.reportAlertsNone),
        for (final a in c.alerts)
          Padding(
            // A 2 dp gap, as on the Alerts tab.
            padding: const EdgeInsets.only(bottom: 2),
            child: CodedBand(
              severity: a.severity == Severity.danger
                  ? BandSeverity.danger
                  : BandSeverity.warning,
              text: l10n.alertText(a, batchCode: c.batchCodes[a.batchId]),
              code: c.pondCodes[a.pondId],
              colour: colours[a.pondId],
            ),
          ),

        _Heading(l10n.reportHealth),
        if (c.health.isEmpty) _Empty(l10n.reportHealthNone),
        for (final h in orderHealth(c.health, c.pondCodes)) ...[
          pond(h.pondId, Text(_deathsText(l10n, h, locale))),
          for (final e in healthEntries(h)) ..._healthEntry(context, e),
        ],

        _Heading(l10n.reportWater),
        if (water.isEmpty) _Empty(l10n.reportNoFish),
        for (final w in water)
          pond(
            w.pondId,
            w.at == null
                ? Text(l10n.reportNoReading)
                : WaterValues(
                    temperatureC: w.temperatureC,
                    ph: w.ph,
                    oxygenMgL: w.oxygenMgL,
                    colour: w.colour,
                    issues: {for (final i in w.issues) i.param: i.severity},
                    leading: Text(formatDate(w.at!)),
                  ),
          ),

        _Heading(l10n.reportGrowth),
        if (growth.isEmpty) _Empty(l10n.reportNoFish),
        for (final g in growth) ...[
          pond(
            g.pondId,
            Text(
              [
                l10n.reportGrowthLine(
                  c.batchCodes[g.batchId] ?? '?',
                  formatGrams(g.avgWeightG, locale),
                  formatDate(g.weighedOn),
                ),
                approx(formatKg(g.biomassG, locale)),
                approx(l10n.pondFishCount(formatCount(g.liveCount, locale))),
              ].join(', '),
            ),
          ),
          _Sub(child: _GrowthFigures(growth: g)),
        ],

        _Heading(l10n.reportFeed),
        if (c.feed.isEmpty) _Empty(l10n.reportNoFeed),
        for (final f
            in [...c.feed]..sort(
              (a, b) => (c.pondCodes[a.pondId] ?? '').compareTo(
                c.pondCodes[b.pondId] ?? '',
              ),
            ))
          pond(
            f.pondId,
            Text(
              formatKg(f.feedG, locale),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        if (c.feed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(child: Text(l10n.reportFeedTotal, style: _bold)),
                Text(
                  formatKg(c.feedTotalG, locale),
                  style: _bold.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        for (final text in l10n.reportFeedStockLines(c.feedStock, locale))
          c.feedStock == null ? _Empty(text) : _Plain(text),

        _Heading(l10n.reportNext),
        if (c.next.isEmpty) _Empty(l10n.reportNextNone),
        for (final n in c.next)
          pond(
            n.pondId,
            Text(
              l10n.labelValue(
                formatDate(n.date),
                l10n.reportNextText(
                  n,
                  pond: c.pondCodes[n.pondId] ?? '?',
                  batch: c.batchCodes[n.batchId] ?? '?',
                ),
              ),
            ),
          ),

        _Heading(l10n.reportObservations),
        if (split.problems.isEmpty &&
            split.notes.isEmpty &&
            split.inOrder.isEmpty &&
            c.visitPhotoKeys.isEmpty &&
            visitPhotos == null)
          _Empty(l10n.reportObservationsNone),
        for (final o in [...split.problems, ...split.notes]) ...[
          pond(
            o.pondId,
            Text(
              o.note == null
                  ? l10n.observationCategory(o.category)
                  : l10n.labelValue(
                      l10n.observationCategory(o.category),
                      o.note!,
                    ),
            ),
            icon: o.ok == false ? Icons.report_problem : Icons.notes,
            ic: o.ok == false ? context.dobo.warning : null,
          ),
          if (o.photoKeys.isNotEmpty)
            _Sub(child: ReportPhotos(keys: o.photoKeys)),
        ],
        if (split.inOrder.isNotEmpty)
          _PondLine(
            icon: Icons.check_circle,
            iconColour: context.dobo.ok,
            child: Text(l10n.reportInOrder(split.inOrder.join(', '))),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: visitPhotos ?? ReportPhotos(keys: c.visitPhotoKeys),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static const _bold = TextStyle(fontWeight: FontWeight.w700);

  String _deathsText(AppLocalizations l10n, PondHealth h, Locale locale) {
    final deaths = l10n.reportDeaths(formatCount(h.deaths, locale));
    if (h.byObserver.isEmpty) return deaths;
    return l10n.reportDeathsBy(
      deaths,
      [
        for (final o in h.byObserver)
          l10n.reportObserverDeaths(
            o.name ?? l10n.reportUnknownPerson,
            formatCount(o.deaths, locale),
          ),
      ].join(', '),
    );
  }

  List<Widget> _healthEntry(BuildContext context, HealthEntry e) {
    final l10n = AppLocalizations.of(context);
    final danger = context.dobo.danger;
    String actions(Set<HealthAction> a) =>
        [for (final x in a) l10n.healthAction(x)].join(', ');
    return switch (e) {
      SignsEntry(:final signs) => [
        _Sub(
          icon: Icons.error,
          iconColour: danger,
          child: Text(
            l10n.reportSigns(
              formatDate(signs.date),
              signs.signs.map(l10n.warningSign).join(', '),
            ),
          ),
        ),
      ],
      EventEntry(:final event) => [
        _Sub(
          icon: Icons.error,
          iconColour: danger,
          child: Text(
            l10n.reportHealthEventLine(
              formatDate(event.at),
              [
                if (event.signs.isNotEmpty)
                  event.signs.map(l10n.warningSign).join(', '),
                ?event.suspectedIssue,
                if (event.actions.isNotEmpty) actions(event.actions),
              ].join(', '),
            ),
          ),
        ),
        if (event.photoKeys.isNotEmpty)
          _Sub(child: ReportPhotos(keys: event.photoKeys)),
      ],
      TreatmentEntry(:final treatment) => [
        _Sub(
          icon: Icons.medication,
          child: Text(
            l10n.reportTreatmentLine(
              formatDate(treatment.at),
              treatment.product,
              treatment.dose,
            ),
          ),
        ),
      ],
    };
  }
}

/// A batch's FCR with its trend arrow (worse in danger, as on the pond
/// page) and its survival.
class _GrowthFigures extends StatelessWidget {
  const _GrowthFigures({required this.growth});

  final BatchGrowth growth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final c = context.dobo;
    final g = growth;
    final fcr = switch (g.fcrNote) {
      FcrNote.shared => '— (${l10n.reportFcrShared})',
      FcrNote.noSample => '— (${l10n.reportFcrNoSample})',
      FcrNote.stalled => l10n.fcrStalled,
      null => formatDecimal(g.fcr!, locale, decimals: 2),
    };
    final (arrow, colour) = switch (g.trend) {
      FcrTrend.worse => (' ↑', c.danger),
      FcrTrend.better => (' ↓', c.ok),
      FcrTrend.same => (' →', null),
      null => ('', null),
    };
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: l10n.fcrValue(fcr)),
          TextSpan(
            text: arrow,
            style: TextStyle(color: colour, fontWeight: FontWeight.w700),
          ),
          if (g.survival != null)
            TextSpan(
              text:
                  ', ${l10n.survivalValue(formatDecimal(g.survival! * 100, locale, decimals: 0))}',
            ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// What "nothing" means in a section, quietly.
class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: context.dobo.inkMuted),
    ),
  );
}

class _Plain extends StatelessWidget {
  const _Plain(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Text(text),
  );
}

/// A report line about a pond: its code (and swatch) in the 72 dp column,
/// then an optional icon and [child]. No code: the column stays empty.
class _PondLine extends StatelessWidget {
  const _PondLine({
    required this.child,
    this.code,
    this.colour,
    this.icon,
    this.iconColour,
  });

  final Widget child;
  final String? code;
  final PondColour? colour;
  final IconData? icon;
  final Color? iconColour;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _codeColumn - 16,
          child: code == null
              ? null
              : Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: PondCode(code: code!, colour: colour),
                  ),
                ),
        ),
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColour),
          const SizedBox(width: 6),
        ],
        Expanded(child: child),
      ],
    ),
  );
}

/// A line under a pond's line, starting after the code column.
class _Sub extends StatelessWidget {
  const _Sub({required this.child, this.icon, this.iconColour});

  final Widget child;
  final IconData? icon;
  final Color? iconColour;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(_codeColumn, 2, 16, 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColour),
          const SizedBox(width: 6),
        ],
        Expanded(child: child),
      ],
    ),
  );
}

/// A report's photos, those on this phone shown, the others as
/// placeholders; a tap shows one full screen.
class ReportPhotos extends StatelessWidget {
  const ReportPhotos({super.key, required this.keys});

  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    if (keys.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final k in keys)
            InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog(
                  child: InteractiveViewer(
                    child: PhotoThumb(photoKey: k, size: 320),
                  ),
                ),
              ),
              child: PhotoThumb(photoKey: k, size: 96),
            ),
        ],
      ),
    );
  }
}
