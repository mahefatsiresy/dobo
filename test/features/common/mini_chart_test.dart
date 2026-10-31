import 'package:dobo/features/common/mini_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime d(int day) => DateTime(2026, 3, day);

  Future<void> pump(
    WidgetTester tester,
    List<ChartPoint> points, {
    ChartStyle style = ChartStyle.line,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MiniChart(
          series: [ChartSeries(points: points, color: Colors.blue)],
          style: style,
          title: 'Poids moyen',
          formatY: (v) => v.toStringAsFixed(0),
          emptyText: 'Pas encore de données',
        ),
      ),
    ),
  );

  testWidgets('no points shows emptyText', (tester) async {
    await pump(tester, const []);
    expect(find.text('Pas encore de données'), findsOneWidget);
    await pump(tester, [ChartPoint(d(1), null)]);
    expect(find.text('Pas encore de données'), findsOneWidget);
  });

  testWidgets('one point renders without exception', (tester) async {
    for (final style in ChartStyle.values) {
      await pump(tester, [ChartPoint(d(1), 12)], style: style);
      expect(tester.takeException(), isNull);
      expect(find.text('Pas encore de données'), findsNothing);
    }
  });

  testWidgets('null y values are skipped', (tester) async {
    await pump(tester, [
      ChartPoint(d(1), 1),
      ChartPoint(d(5), null),
      ChartPoint(d(9), 3),
    ]);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('a flagged point alone still draws', (tester) async {
    await pump(tester, [
      ChartPoint(d(1), null, flagged: true),
    ], style: ChartStyle.points);
    expect(tester.takeException(), isNull);
    expect(find.text('Pas encore de données'), findsNothing);
  });

  testWidgets('shows first and last date labels', (tester) async {
    await pump(tester, [
      ChartPoint(d(1), 10),
      ChartPoint(d(8), 14),
      ChartPoint(d(15), 20),
    ], style: ChartStyle.bars);
    expect(find.text('01/03'), findsOneWidget);
    expect(find.text('15/03'), findsOneWidget);
  });

  testWidgets('semantics label is the title', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, [ChartPoint(d(1), 10), ChartPoint(d(2), 11)]);
    expect(find.bySemanticsLabel(RegExp('Poids moyen')), findsWidgets);
    handle.dispose();
  });
}
