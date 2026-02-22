import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/colors.dart';
import '../../../providers/dashboard_insights_provider.dart';

/// Line chart showing team hitting % over recent games with rolling average.
class EfficiencyTrendChart extends StatelessWidget {
  final List<EfficiencyTrendPoint> data;

  const EfficiencyTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.length < 3) {
      return _buildEmptyState(context);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final targetLine = 0.250;
    final dangerLine = 0.200;

    final allValues = data.map((d) => d.hittingPct).toList();
    final rollingValues = data
        .where((d) => d.rollingAvg != null)
        .map((d) => d.rollingAvg!)
        .toList();
    final allPcts = [...allValues, ...rollingValues, targetLine, dangerLine];
    final maxY = allPcts.reduce((a, b) => a > b ? a : b) * 1.2;
    final minY = (allPcts.reduce((a, b) => a < b ? a : b) * 0.8).clamp(0.0, 0.15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Offensive Efficiency Trend',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.050,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.onSurface.withAlpha(20),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 0.050,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        '.${(value * 1000).round().toString().padLeft(3, '0')}',
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
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      // Show abbreviated opponent name
                      final label = data[idx].gameLabel;
                      final short = label.length > 8
                          ? '${label.substring(0, 8)}…'
                          : label;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Transform.rotate(
                          angle: -0.4,
                          child: Text(
                            short,
                            style: TextStyle(
                              fontSize: 8,
                              color: colorScheme.onSurface.withAlpha(128),
                            ),
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
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: targetLine,
                    color: StatLineColors.pointScored.withAlpha(100),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(
                        fontSize: 9,
                        color: StatLineColors.pointScored.withAlpha(180),
                      ),
                      labelResolver: (_) => '.250 target',
                    ),
                  ),
                  HorizontalLine(
                    y: dangerLine,
                    color: StatLineColors.pointLost.withAlpha(100),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.bottomRight,
                      style: TextStyle(
                        fontSize: 9,
                        color: StatLineColors.pointLost.withAlpha(180),
                      ),
                      labelResolver: (_) => '.200 danger',
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                // Individual game dots
                LineChartBarData(
                  spots: List.generate(
                    data.length,
                    (i) => FlSpot(i.toDouble(), data[i].hittingPct),
                  ),
                  isCurved: false,
                  color: Colors.transparent,
                  barWidth: 0,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isWin = data[index].isWin;
                      return FlDotCirclePainter(
                        radius: 5,
                        color: isWin
                            ? StatLineColors.pointScored
                            : StatLineColors.pointLost,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
                // Rolling average smooth line
                if (data.any((d) => d.rollingAvg != null))
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .where((e) => e.value.rollingAvg != null)
                        .map((e) => FlSpot(e.key.toDouble(), e.value.rollingAvg!))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: StatLineColors.primaryAccent,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: StatLineColors.primaryAccent.withAlpha(30),
                    ),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.spotIndex;
                      if (idx < 0 || idx >= data.length) {
                        return null;
                      }
                      final point = data[idx];
                      final pctStr = '.${(spot.y * 1000).round().toString().padLeft(3, '0')}';
                      return LineTooltipItem(
                        '${point.gameLabel}\n$pctStr',
                        TextStyle(
                          color: point.isWin
                              ? StatLineColors.pointScored
                              : StatLineColors.pointLost,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
          ),
          const SizedBox(height: 8),
          Text(
            'Need 3+ games to show trends',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
          ),
        ],
      ),
    );
  }
}
