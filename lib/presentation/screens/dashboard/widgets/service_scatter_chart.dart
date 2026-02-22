import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/colors.dart';
import '../../../providers/dashboard_insights_provider.dart';

/// Scatter chart showing service aces vs errors per game, colored by W/L.
class ServiceScatterChart extends StatelessWidget {
  final List<ServiceEfficiencyPoint> data;

  const ServiceScatterChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    final colorScheme = Theme.of(context).colorScheme;

    final maxAces = data.map((d) => d.aces).reduce((a, b) => a > b ? a : b);
    final maxErrors = data.map((d) => d.errors).reduce((a, b) => a > b ? a : b);
    final axisMax = ((maxAces > maxErrors ? maxAces : maxErrors) + 2).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Service Efficiency',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              _legendDot(context, 'Win', StatLineColors.pointScored),
              const SizedBox(width: 12),
              _legendDot(context, 'Loss', StatLineColors.pointLost),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ScatterChart(
            ScatterChartData(
              minX: 0,
              maxX: axisMax,
              minY: 0,
              maxY: axisMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.onSurface.withAlpha(20),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: colorScheme.onSurface.withAlpha(20),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Service Errors',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min || value % 2 != 0) {
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
                  axisNameWidget: Text(
                    'Service Aces',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min || value % 2 != 0) {
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
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              scatterSpots: data.map((point) {
                return ScatterSpot(
                  point.aces.toDouble(),
                  point.errors.toDouble(),
                  dotPainter: FlDotCirclePainter(
                    radius: 6,
                    color: point.isWin
                        ? StatLineColors.pointScored
                        : StatLineColors.pointLost,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                );
              }).toList(),
              scatterTouchData: ScatterTouchData(
                enabled: true,
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipItems: (ScatterSpot spot) {
                    final idx = data.indexWhere(
                      (d) => d.aces.toDouble() == spot.x && d.errors.toDouble() == spot.y,
                    );
                    if (idx < 0) return null;
                    final point = data[idx];
                    final wl = point.isWin ? 'W' : 'L';
                    return ScatterTooltipItem(
                      '${point.gameLabel}: ${point.aces}A, ${point.errors}E ($wl)',
                      textStyle: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
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
            Icons.scatter_plot,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
          ),
          const SizedBox(height: 8),
          Text(
            'Need game data to show service efficiency',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
          ),
        ],
      ),
    );
  }
}
