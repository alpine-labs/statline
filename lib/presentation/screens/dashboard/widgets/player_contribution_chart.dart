import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/colors.dart';
import '../../../providers/dashboard_insights_provider.dart';

/// Stacked horizontal bar chart showing top 5 players' kills, digs, and aces.
class PlayerContributionChart extends StatelessWidget {
  final List<PlayerContributionData> data;

  const PlayerContributionChart({super.key, required this.data});

  static const _killsColor = StatLineColors.nordicSlate;
  static const _digsColor = StatLineColors.nordicSage;
  static const _acesColor = StatLineColors.logoGreen;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final maxTotal = data
        .map((d) => d.kills + d.digs + d.aces)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final adjustedMax = maxTotal * 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Top 5 Player Contributions',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              _legendItem(context, 'Kills', _killsColor),
              const SizedBox(width: 12),
              _legendItem(context, 'Digs', _digsColor),
              const SizedBox(width: 12),
              _legendItem(context, 'Aces', _acesColor),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: adjustedMax,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (groupIndex >= data.length) return null;
                    final player = data[groupIndex];
                    return BarTooltipItem(
                      '${player.playerName}\n'
                      'K: ${player.kills}  D: ${player.digs}  A: ${player.aces}',
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
                horizontalInterval: adjustedMax / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.onSurface.withAlpha(20),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final name = data[idx].playerName;
                      final short = name.length > 10
                          ? '${name.substring(0, 10)}…'
                          : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          short,
                          style: TextStyle(
                            fontSize: 9,
                            color: colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(data.length, (i) {
                final player = data[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (player.kills + player.digs + player.aces).toDouble(),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      rodStackItems: [
                        BarChartRodStackItem(
                          0,
                          player.kills.toDouble(),
                          _killsColor,
                        ),
                        BarChartRodStackItem(
                          player.kills.toDouble(),
                          (player.kills + player.digs).toDouble(),
                          _digsColor,
                        ),
                        BarChartRodStackItem(
                          (player.kills + player.digs).toDouble(),
                          (player.kills + player.digs + player.aces).toDouble(),
                          _acesColor,
                        ),
                      ],
                      color: Colors.transparent,
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

  Widget _legendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
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
            'No player data yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
          ),
        ],
      ),
    );
  }
}
