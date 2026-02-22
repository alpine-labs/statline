import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/models/game_period.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

/// Compact scoreboard widget — 2-row layout optimized for mobile screen space.
///
/// Row 1: Timeout dots | Team name + score | dash | Opponent + score | Timeout dots
/// Row 2: Set history | sub count | side-out %
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
  final int subsThisSet;
  final int maxSubsPerSet;
  final int firstBallSideouts;
  final int totalSideouts;
  final int sideoutOpportunities;

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
    this.subsThisSet = 0,
    this.maxSubsPerSet = 15,
    this.firstBallSideouts = 0,
    this.totalSideouts = 0,
    this.sideoutOpportunities = 0,
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

          // Row 2: Set history + subs + side-out stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Set history
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
              // Compact sub count
              if (subsThisSet > 0)
                Text(
                  '  S:$subsThisSet',
                  style: TextStyle(
                    color: _subsColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              // Side-out %
              if (sideoutOpportunities > 0) ...[
                Text(
                  '  SO:${(totalSideouts / sideoutOpportunities * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white.withAlpha(153),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (totalSideouts > 0)
                  Text(
                    ' 1st:${(firstBallSideouts / totalSideouts * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withAlpha(102),
                      fontSize: 11,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color get _subsColor {
    if (subsThisSet >= maxSubsPerSet) return Colors.red;
    if (subsThisSet > maxSubsPerSet * 0.8) return Colors.yellow;
    return Colors.white.withAlpha(128);
  }

  /// Timeout dots: tap to record, long-press to undo.
  /// Us = amber, Them = red.
  Widget _buildTimeoutDots(int used, int max, bool isUs) {
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(max, (i) {
          final isFilled = i < used;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? (isUs ? Colors.amber : Colors.redAccent)
                    : Colors.transparent,
                border: Border.all(
                  color: isFilled
                      ? (isUs ? Colors.amber : Colors.redAccent)
                      : Colors.white38,
                  width: 1.5,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
