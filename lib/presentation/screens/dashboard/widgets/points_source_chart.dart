import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/colors.dart';
import '../../../providers/dashboard_insights_provider.dart';

/// Donut chart showing the source of team points.
class PointsSourceChart extends StatelessWidget {
  final PointsSourceData data;

  const PointsSourceChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.total == 0) {
      return _buildEmptyState(context);
    }

    final colorScheme = Theme.of(context).colorScheme;

    final sections = <_SliceInfo>[
      _SliceInfo('Kills', data.kills, StatLineColors.nordicSlate),
      _SliceInfo('Aces', data.aces, StatLineColors.logoGreen),
      _SliceInfo('Blocks', data.blocks, StatLineColors.nordicMedium),
      _SliceInfo('Other', data.opponentErrors, StatLineColors.nordicSage),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Points Source',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections.map((s) {
                          final pct = data.total > 0
                              ? (s.value / data.total * 100)
                              : 0.0;
                          return PieChartSectionData(
                            value: s.value.toDouble(),
                            color: s.color,
                            radius: 28,
                            title: pct >= 10
                                ? '${pct.round()}%'
                                : '',
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${data.total}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'pts',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withAlpha(128),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${s.label} (${s.value})',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
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
            Icons.pie_chart_outline,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
          ),
          const SizedBox(height: 8),
          Text(
            'No points data yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
          ),
        ],
      ),
    );
  }
}

class _SliceInfo {
  final String label;
  final int value;
  final Color color;
  const _SliceInfo(this.label, this.value, this.color);
}
