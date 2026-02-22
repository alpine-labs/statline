import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/colors.dart';
import '../../../providers/dashboard_insights_provider.dart';

/// Grouped bar chart comparing home vs away performance.
class HomeAwayChart extends StatelessWidget {
  final HomeAwayComparison data;

  const HomeAwayChart({super.key, required this.data});

  static const _homeColor = StatLineColors.nordicSlate;
  static const _awayColor = Color(0xFFE8A838);

  @override
  Widget build(BuildContext context) {
    if (data.awayGames == 0) {
      return _buildAllHomeState(context);
    }
    if (data.homeGames == 0 && data.awayGames == 0) {
      return _buildEmptyState(context);
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Categories: Win%, Hitting%, Aces/G, Digs/G
    final categories = ['Win%', 'Hit%', 'Aces/G', 'Digs/G'];
    final homeValues = [
      data.homeWinPct,
      data.homeHittingPct,
      data.homeAcesPerGame,
      data.homeDigsPerGame,
    ];
    final awayValues = [
      data.awayWinPct,
      data.awayHittingPct,
      data.awayAcesPerGame,
      data.awayDigsPerGame,
    ];

    // Compute per-category max for normalized Y axis
    final maxValues = <double>[];
    for (int i = 0; i < categories.length; i++) {
      final max = homeValues[i] > awayValues[i] ? homeValues[i] : awayValues[i];
      maxValues.add(max);
    }

    // Use a unified scale: normalize each bar to percentage of its category max
    final globalMax = [
      100.0,  // Win%
      0.5,    // Hitting%
      _ceilToHalf(maxValues[2] * 1.3),  // Aces/G
      _ceilToHalf(maxValues[3] * 1.3),  // Digs/G
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Home vs Away',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              _legendItem(context, 'Home 🏠', _homeColor),
              const SizedBox(width: 16),
              _legendItem(context, 'Away 🚌', _awayColor),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1.0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final cat = categories[groupIndex];
                    final val = rodIndex == 0
                        ? homeValues[groupIndex]
                        : awayValues[groupIndex];
                    final label = rodIndex == 0 ? 'Home' : 'Away';
                    String formatted;
                    if (groupIndex == 0) {
                      formatted = '${val.round()}%';
                    } else if (groupIndex == 1) {
                      formatted = '.${(val * 1000).round().toString().padLeft(3, '0')}';
                    } else {
                      formatted = val.toStringAsFixed(1);
                    }
                    return BarTooltipItem(
                      '$label $cat: $formatted',
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
                horizontalInterval: 0.25,
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
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(categories.length, (i) {
                final homeNorm = globalMax[i] > 0
                    ? (homeValues[i] / globalMax[i]).clamp(0.0, 1.0)
                    : 0.0;
                final awayNorm = globalMax[i] > 0
                    ? (awayValues[i] / globalMax[i]).clamp(0.0, 1.0)
                    : 0.0;
                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: homeNorm,
                      width: 16,
                      color: _homeColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                    BarChartRodData(
                      toY: awayNorm,
                      width: 16,
                      color: _awayColor,
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

  double _ceilToHalf(double value) {
    if (value <= 0) return 1.0;
    return (value * 2).ceilToDouble() / 2;
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildAllHomeState(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
          ),
          const SizedBox(height: 8),
          Text(
            'All games have been at home so far',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
          ),
        ],
      ),
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
            'No game data yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
          ),
        ],
      ),
    );
  }
}
