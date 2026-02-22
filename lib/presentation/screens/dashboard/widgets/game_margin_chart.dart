import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/dashboard_insights_provider.dart';

/// Bar chart showing game distribution by margin (blowout/close wins and losses).
class GameMarginChart extends StatelessWidget {
  final GameMarginData data;

  const GameMarginChart({super.key, required this.data});

  static const _blowoutWinColor = Color(0xFF2E7D32);
  static const _winColor = Color(0xFF81C784);
  static const _lossColor = Color(0xFFEF9A9A);
  static const _blowoutLossColor = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    if (data.total == 0) {
      return _buildEmptyState(context);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final categories = ['3-0 W', 'W', 'L', '0-3 L'];
    final values = [
      data.blowoutWins.toDouble(),
      data.wins.toDouble(),
      data.losses.toDouble(),
      data.blowoutLosses.toDouble(),
    ];
    final colors = [_blowoutWinColor, _winColor, _lossColor, _blowoutLossColor];
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final yMax = maxY < 1 ? 1.0 : (maxY + 1).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Game Margins',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: yMax,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final count = values[groupIndex].toInt();
                    final label = count == 1 ? '1 game' : '$count games';
                    return BarTooltipItem(
                      label,
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.onSurface.withAlpha(20),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        '${value.toInt()}',
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
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= categories.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          categories[idx],
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withAlpha(160),
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
              barGroups: List.generate(4, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      width: 28,
                      color: colors[i],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ],
                );
              }),
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
            Icons.bar_chart,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
          ),
          const SizedBox(height: 8),
          Text(
            'No completed games yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
          ),
        ],
      ),
    );
  }
}
