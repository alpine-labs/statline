import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/colors.dart';

/// Spider/radar chart showing a player's stat profile normalized to team averages.
///
/// Each axis represents a per-set metric. Values are normalized so that
/// 1.0 = team average, >1.0 = above average, capped at 2.0.
class RadarChartWidget extends StatelessWidget {
  final String playerName;
  final Map<String, double> playerMetrics;
  final Map<String, double> teamAverages;
  final String? title;

  const RadarChartWidget({
    super.key,
    required this.playerName,
    required this.playerMetrics,
    required this.teamAverages,
    this.title,
  });

  static const _axisKeys = ['K/S', 'D/S', 'A/S', 'B/S', 'Ace/S', 'Pass Avg'];

  double _normalize(String key) {
    final teamAvg = teamAverages[key] ?? 0.0;
    if (teamAvg == 0) return 0.0;
    final playerVal = playerMetrics[key] ?? 0.0;
    return min(playerVal / teamAvg, 2.0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = StatLineColors.primaryAccent;

    final playerEntries = _axisKeys.map((k) => RadarEntry(value: _normalize(k))).toList();
    final teamEntries = _axisKeys.map((_) => const RadarEntry(value: 1.0)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title ?? '$playerName – Stat Profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: RadarChart(
                RadarChartData(
                  radarTouchData: RadarTouchData(enabled: false),
                  dataSets: [
                    // Team average baseline (gray outline)
                    RadarDataSet(
                      dataEntries: teamEntries,
                      borderColor: colorScheme.onSurface.withAlpha(77),
                      borderWidth: 1.5,
                      fillColor: Colors.transparent,
                      entryRadius: 0,
                    ),
                    // Player profile (filled accent)
                    RadarDataSet(
                      dataEntries: playerEntries,
                      borderColor: accentColor,
                      borderWidth: 2,
                      fillColor: accentColor.withAlpha(51),
                      entryRadius: 3,
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: BorderSide(
                    color: colorScheme.onSurface.withAlpha(26),
                  ),
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withAlpha(179),
                    fontWeight: FontWeight.w500,
                  ),
                  getTitle: (index, angle) =>
                      RadarChartTitle(text: _axisKeys[index]),
                  tickCount: 4,
                  ticksTextStyle: TextStyle(
                    fontSize: 9,
                    color: colorScheme.onSurface.withAlpha(77),
                  ),
                  tickBorderData: BorderSide(
                    color: colorScheme.onSurface.withAlpha(26),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(accentColor),
                const SizedBox(width: 4),
                Text(
                  playerName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                _legendDot(colorScheme.onSurface.withAlpha(77)),
                const SizedBox(width: 4),
                Text(
                  'Team Avg',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
