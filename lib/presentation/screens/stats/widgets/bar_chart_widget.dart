import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/colors.dart';

/// Reusable bar chart wrapper using fl_chart.
class BarChartWidget extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<double> values;
  final Color? barColor;

  const BarChartWidget({
    super.key,
    required this.title,
    required this.labels,
    required this.values,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = barColor ?? StatLineColors.primaryAccent;
    final colorScheme = Theme.of(context).colorScheme;

    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxY = values.reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = maxY * 1.3;

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
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: adjustedMaxY,
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
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toStringAsFixed(0),
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
                          if (idx < 0 || idx >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[idx],
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
                  barGroups: List.generate(values.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: color,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tooltipMargin: 4,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.toStringAsFixed(0),
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
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
