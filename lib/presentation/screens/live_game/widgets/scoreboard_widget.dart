import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/models/game_period.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

/// A labeled value to display in the scoreboard's secondary row.
class ScoreboardMetric {
  final String label;
  final String value;
  final Color? color;

  const ScoreboardMetric({
    required this.label,
    required this.value,
    this.color,
  });
}

/// Compact scoreboard widget — 2-row layout optimized for mobile screen space.
///
/// Row 1: Timeout dots | Team name + score | dash | Opponent + score | Timeout dots
/// Row 2: Set/period history | sport-specific secondary metrics
class ScoreboardWidget extends StatelessWidget {
  final String teamName;
  final String opponentName;
  final int scoreUs;
  final int scoreThem;
  final List<GamePeriod> periods;
  final int timeoutsUs;
  final int timeoutsThem;
  final int maxTimeouts;
  final VoidCallback? onTimeoutUs;
  final VoidCallback? onTimeoutThem;
  final VoidCallback? onUndoTimeoutUs;
  final VoidCallback? onUndoTimeoutThem;
  /// Sport-specific metrics displayed in the secondary row.
  final List<ScoreboardMetric> secondaryMetrics;

  const ScoreboardWidget({
    super.key,
    required this.teamName,
    required this.opponentName,
    required this.scoreUs,
    required this.scoreThem,
    required this.periods,
    this.timeoutsUs = 0,
    this.timeoutsThem = 0,
    this.maxTimeouts = 2,
    this.onTimeoutUs,
    this.onTimeoutThem,
    this.onUndoTimeoutUs,
    this.onUndoTimeoutThem,
    this.secondaryMetrics = const [],
  });

  @override
  Widget build(BuildContext context) {
    final usWinning = scoreUs > scoreThem;
    final themWinning = scoreThem > scoreUs;

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Row 1: Scores with timeout dots on sides
          Row(
            children: [
              // Us side: timeout dots + score
              Expanded(
                child: Row(
                  children: [
                    _buildTimeoutDots(timeoutsUs, maxTimeouts, true),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'US',
                            style: TextStyle(
                              color: usWinning
                                  ? StatLineColors.pointScored
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$scoreUs',
                            style: StatLineTypography.scoreDisplay.copyWith(
                              color: usWinning
                                  ? StatLineColors.pointScored
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Center dash
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '-',
                  style: StatLineTypography.scoreDisplay.copyWith(
                    color: Colors.white.withAlpha(77),
                  ),
                ),
              ),
              // Them side: score + timeout dots
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            opponentName.length > 10
                                ? opponentName.substring(0, 10)
                                : opponentName,
                            style: TextStyle(
                              color: themWinning
                                  ? StatLineColors.pointLost
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$scoreThem',
                            style: StatLineTypography.scoreDisplay.copyWith(
                              color: themWinning
                                  ? StatLineColors.pointLost
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTimeoutDots(timeoutsThem, maxTimeouts, false),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Row 2: Period history + sport-specific secondary metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Period history
              if (periods.length > 1 ||
                  (periods.isNotEmpty && periods.first.scoreUs > 0))
                for (int i = 0; i < periods.length; i++) ...[
                  if (i > 0)
                    Text(
                      ' | ',
                      style: TextStyle(
                        color: Colors.white.withAlpha(51),
                        fontSize: 11,
                      ),
                    ),
                  Text(
                    '${periods[i].scoreUs}-${periods[i].scoreThem}',
                    style: TextStyle(
                      color: i == periods.length - 1
                          ? Colors.white
                          : Colors.white.withAlpha(128),
                      fontSize: 11,
                      fontWeight: i == periods.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              // Sport-specific secondary metrics
              for (final metric in secondaryMetrics)
                Text(
                  '  ${metric.label}:${metric.value}',
                  style: TextStyle(
                    color: metric.color ?? Colors.white.withAlpha(153),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Timeout button: tappable "TO 0/2" text. Tap to record, long-press to undo.
  /// Us = amber, Them = red.
  Widget _buildTimeoutDots(int used, int max, bool isUs) {
    final color = used > 0
        ? (isUs ? Colors.amber : Colors.redAccent)
        : Colors.white38;
    final atMax = used >= max;

    return GestureDetector(
      onTap: () {
        if (isUs) {
          onTimeoutUs?.call();
        } else {
          onTimeoutThem?.call();
        }
        HapticFeedback.lightImpact();
      },
      onLongPress: () {
        if (isUs) {
          onUndoTimeoutUs?.call();
        } else {
          onUndoTimeoutThem?.call();
        }
        HapticFeedback.mediumImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withAlpha(102), width: 1),
          color: atMax ? color.withAlpha(38) : Colors.transparent,
        ),
        child: Text(
          'TO $used/$max',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: atMax ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
