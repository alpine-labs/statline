import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/colors.dart';

/// Reusable line chart wrapper using fl_chart.
class LineChartWidget extends StatelessWidget {
  final String title;
  final List<String> xLabels;
  final List<double> dataPoints;
  final Color? lineColor;

  const LineChartWidget({
    super.key,
    required this.title,
    required this.xLabels,
    required this.dataPoints,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = lineColor ?? StatLineColors.primaryAccent;
    final colorScheme = Theme.of(context).colorScheme;

    if (dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxY = dataPoints.reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = maxY * 1.2;

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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: adjustedMaxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.onSurface.withAlpha(26),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          String text;
                          if (adjustedMaxY <= 1.0) {
                            text = '.${(value * 1000).round().toString().padLeft(3, '0')}';
                          } else {
                            text = value.toStringAsFixed(0);
                          }
                          return Text(
                            text,
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
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= xLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              xLabels[idx],
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
                  minY: 0,
                  maxY: adjustedMaxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        dataPoints.length,
                        (i) => FlSpot(i.toDouble(), dataPoints[i]),
                      ),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withAlpha(38),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          String text;
                          if (adjustedMaxY <= 1.0) {
                            text = '.${(spot.y * 1000).round().toString().padLeft(3, '0')}';
                          } else {
                            text = spot.y.toStringAsFixed(1);
                          }
                          return LineTooltipItem(
                            text,
                            TextStyle(
                              color: color,
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
}
