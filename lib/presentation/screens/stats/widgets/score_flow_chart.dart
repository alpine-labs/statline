import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/colors.dart';

/// Point-by-point score differential chart for a single set.
///
/// X-axis: rally number. Y-axis: score differential (us − them).
/// Green fill when ahead, red fill when behind.
class ScoreFlowChart extends StatelessWidget {
  final String title;
  final List<({int rallyNumber, int scoreUs, int scoreThem})> scoreProgression;

  const ScoreFlowChart({
    super.key,
    required this.title,
    required this.scoreProgression,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (scoreProgression.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[
      const FlSpot(0, 0), // start at 0-0
      ...scoreProgression.map(
        (e) => FlSpot(
          e.rallyNumber.toDouble(),
          (e.scoreUs - e.scoreThem).toDouble(),
        ),
      ),
    ];

    final diffs = spots.map((s) => s.y);
    final rawMax = diffs.reduce((a, b) => a > b ? a : b);
    final rawMin = diffs.reduce((a, b) => a < b ? a : b);
    final absMax = [rawMax.abs(), rawMin.abs(), 1.0].reduce((a, b) => a > b ? a : b);
    final maxY = (absMax + 1).ceilToDouble();
    final minY = -maxY;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.onSurface.withAlpha(26),
                      strokeWidth: 1,
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: colorScheme.onSurface.withAlpha(100),
                        strokeWidth: 1,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface.withAlpha(128),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _bottomInterval(spots.last.x),
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurface.withAlpha(128),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: StatLineColors.primaryAccent,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      aboveBarData: BarAreaData(
                        show: true,
                        color: StatLineColors.pointLost.withAlpha(50),
                        cutOffY: 0,
                        applyCutOffY: true,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: StatLineColors.pointScored.withAlpha(50),
                        cutOffY: 0,
                        applyCutOffY: true,
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final rally = spot.x.toInt();
                          final diff = spot.y.toInt();
                          final sign = diff > 0 ? '+' : '';
                          return LineTooltipItem(
                            'Rally $rally\n$sign$diff',
                            TextStyle(
                              color: diff >= 0
                                  ? StatLineColors.pointScored
                                  : StatLineColors.pointLost,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _bottomInterval(double maxX) {
    if (maxX <= 10) return 1;
    if (maxX <= 30) return 5;
    return 10;
  }
}
