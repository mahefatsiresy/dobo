import 'package:flutter/material.dart';

import '../../domain/fcr.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../common/mini_chart.dart';
import 'pond_growth.dart';

const _batchColours = [Colors.blue, Colors.orange, Colors.purple, Colors.teal];

/// Average weight, deaths per day and FCR per period of a pond (SPEC F6).
class PondCharts extends StatelessWidget {
  const PondCharts({super.key, required this.growth, required this.batchCodes});

  final PondGrowth growth;
  final Map<String, String> batchCodes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final batches = growth.batches.values.toList();
    Color colour(int i) => _batchColours[i % _batchColours.length];
    String n(double v) => formatNumber(v, locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (batches.length > 1)
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
        MiniChart(
          title: l10n.chartWeight,
          style: ChartStyle.line,
          formatY: n,
          emptyText: l10n.chartEmpty,
          series: [
            for (final (i, b) in batches.indexed)
              ChartSeries(
                color: colour(i),
                points: [
                  for (final p in b.points) ChartPoint(p.date, p.avgWeightG),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        MiniChart(
          title: l10n.chartDeaths,
          style: ChartStyle.bars,
          formatY: n,
          emptyText: l10n.chartEmpty,
          series: [
            ChartSeries(
              color: Colors.red.shade700,
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
        ),
        const SizedBox(height: 16),
        MiniChart(
          title: l10n.chartFcr,
          style: ChartStyle.points,
          formatY: n,
          emptyText: l10n.chartEmpty,
          series: [
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
        ),
      ],
    );
  }
}
