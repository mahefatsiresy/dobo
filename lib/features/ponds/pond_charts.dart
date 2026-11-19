import 'package:flutter/material.dart';

import '../../domain/fcr.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../theme/tokens.dart';
import '../common/mini_chart.dart';
import 'pond_growth.dart';

enum PondChartKind { weight, deaths, fcr }

/// One of a pond's charts (SPEC F6): average weight, deaths per day or FCR
/// per period, under a folded section that names it.
class PondChart extends StatelessWidget {
  const PondChart({
    super.key,
    required this.kind,
    required this.growth,
    required this.batchCodes,
  });

  final PondChartKind kind;
  final PondGrowth growth;
  final Map<String, String> batchCodes;

  /// The chart's name, for its section heading.
  static String title(AppLocalizations l10n, PondChartKind kind) =>
      switch (kind) {
        PondChartKind.weight => l10n.chartWeight,
        PondChartKind.deaths => l10n.chartDeaths,
        PondChartKind.fcr => l10n.chartFcr,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final batches = growth.batches.values.toList();
    final palette = context.dobo.series;
    Color colour(int i) => palette[i % palette.length];
    String n(double v) => formatNumber(v, locale);
    final chart = MiniChart(
      title: title(l10n, kind),
      showTitle: false,
      formatY: n,
      emptyText: l10n.chartEmpty,
      style: switch (kind) {
        PondChartKind.weight => ChartStyle.line,
        PondChartKind.deaths => ChartStyle.bars,
        PondChartKind.fcr => ChartStyle.points,
      },
      series: switch (kind) {
        PondChartKind.weight => [
          for (final (i, b) in batches.indexed)
            ChartSeries(
              color: colour(i),
              points: [
                for (final p in b.points) ChartPoint(p.date, p.avgWeightG),
              ],
            ),
        ],
        PondChartKind.deaths => [
          ChartSeries(
            color: context.dobo.danger,
            points: [
              for (final (i, deaths) in growth.deathsPerDay.indexed)
                ChartPoint(
                  DateTime(
                    growth.deathsFrom.year,
                    growth.deathsFrom.month,
                    growth.deathsFrom.day + i,
                  ),
                  deaths.toDouble(),
                ),
            ],
          ),
        ],
        PondChartKind.fcr => [
          for (final (i, b) in batches.indexed)
            ChartSeries(
              color: colour(i),
              points: [
                for (final p in b.periods)
                  switch (p.fcr) {
                    FcrValue(:final value) => ChartPoint(p.to, value),
                    FcrStalled() => ChartPoint(p.to, null, flagged: true),
                    null => ChartPoint(p.to, null),
                  },
              ],
            ),
        ],
      },
    );
    if (batches.length < 2 || kind == PondChartKind.deaths) return chart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          children: [
            for (final (i, b) in batches.indexed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 12, color: colour(i)),
                  const SizedBox(width: 4),
                  Text(batchCodes[b.batchId] ?? ''),
                ],
              ),
          ],
        ),
        chart,
      ],
    );
  }
}
