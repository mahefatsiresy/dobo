import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/dates.dart';

/// A value on a farm day. A null [y] is skipped; [flagged] draws a red mark
/// on the axis (a stalled FCR has no value to plot).
class ChartPoint {
  const ChartPoint(this.x, this.y, {this.flagged = false});

  final DateTime x;
  final double? y;
  final bool flagged;
}

class ChartSeries {
  const ChartSeries({required this.points, required this.color});

  final List<ChartPoint> points;
  final Color color;
}

enum ChartStyle { line, bars, points }

/// A small chart with its title, lowest and highest values and first and
/// last dates as plain text. Nothing animates: phones are low-end.
class MiniChart extends StatelessWidget {
  const MiniChart({
    super.key,
    required this.series,
    required this.style,
    required this.title,
    required this.formatY,
    this.emptyText,
  });

  final List<ChartSeries> series;
  final ChartStyle style;
  final String title;
  final String Function(double) formatY;
  final String? emptyText;

  static final _day = DateFormat('dd/MM');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = [
      for (final s in series)
        for (final p in s.points)
          if (p.y != null || p.flagged) p,
    ];
    final values = [
      for (final p in all)
        if (p.y != null) p.y!,
    ];
    final header = Text(title, style: theme.textTheme.titleSmall);
    if (all.isEmpty) {
      return Semantics(
        label: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [header, Text(emptyText ?? '')],
        ),
      );
    }

    final first = all.map((p) => p.x).reduce((a, b) => a.isBefore(b) ? a : b);
    final last = all.map((p) => p.x).reduce((a, b) => a.isAfter(b) ? a : b);
    double x(DateTime t) => daysBetween(first, t).toDouble();
    final lo = values.isEmpty ? 0.0 : values.reduce(min);
    final hi = values.isEmpty ? 0.0 : values.reduce(max);
    final minY = style == ChartStyle.line ? lo * 0.9 : 0.0;
    final maxY = hi <= minY ? minY + 1 : hi * 1.1;
    final span = x(last);
    final minX = span == 0 ? -1.0 : 0.0;
    final maxX = span == 0 ? 1.0 : span;
    const flag = Colors.red;

    final grid = FlGridData(show: false);
    final titles = const FlTitlesData(show: false);
    final border = FlBorderData(
      show: true,
      border: Border(
        left: BorderSide(color: theme.dividerColor),
        bottom: BorderSide(color: theme.dividerColor),
      ),
    );

    final Widget chart = switch (style) {
      ChartStyle.line => LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: grid,
          titlesData: titles,
          borderData: border,
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            for (final s in series)
              LineChartBarData(
                spots: [
                  for (final p in s.points)
                    if (p.y != null) FlSpot(x(p.x), p.y!),
                ],
                color: s.color,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
          ],
        ),
        duration: Duration.zero,
      ),
      ChartStyle.bars => BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          gridData: grid,
          titlesData: titles,
          borderData: border,
          barTouchData: BarTouchData(enabled: false),
          barGroups: [
            for (final s in series)
              for (final p in s.points)
                if (p.y != null)
                  BarChartGroupData(
                    x: x(p.x).round(),
                    barRods: [
                      BarChartRodData(toY: p.y!, color: s.color, width: 6),
                    ],
                  ),
          ],
        ),
        duration: Duration.zero,
      ),
      ChartStyle.points => ScatterChart(
        ScatterChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          gridData: grid,
          titlesData: titles,
          borderData: border,
          scatterTouchData: ScatterTouchData(enabled: false),
          scatterSpots: [
            for (final s in series)
              for (final p in s.points)
                if (p.flagged)
                  ScatterSpot(
                    x(p.x),
                    0,
                    dotPainter: FlDotCirclePainter(color: flag, radius: 6),
                  )
                else if (p.y != null)
                  ScatterSpot(
                    x(p.x),
                    p.y!,
                    dotPainter: FlDotCirclePainter(color: s.color, radius: 5),
                  ),
          ],
        ),
        duration: Duration.zero,
      ),
    };

    final small = theme.textTheme.bodySmall;
    return Semantics(
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 4),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (values.isNotEmpty)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatY(hi), style: small),
                      if (lo != hi) Text(formatY(lo), style: small),
                    ],
                  ),
                const SizedBox(width: 4),
                Expanded(child: chart),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_day.format(farmDate(first)), style: small),
              if (span > 0) Text(_day.format(farmDate(last)), style: small),
            ],
          ),
        ],
      ),
    );
  }
}
