import 'package:flutter/material.dart';
import '../../../../domain/models/game_period.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

/// Pinned scoreboard widget shown at the top during live game.
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
  final int subsThisSet;
  final int maxSubsPerSet;
  final VoidCallback? onRecordSub;

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
    this.subsThisSet = 0,
    this.maxSubsPerSet = 15,
    this.onRecordSub,
  });

  @override
  Widget build(BuildContext context) {
    final usWinning = scoreUs > scoreThem;
    final themWinning = scoreThem > scoreUs;

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Team names + current set score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'US',
                      style: TextStyle(
                        color: usWinning
                            ? StatLineColors.pointScored
                            : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              Column(
                children: [
                  Text(
                    'vs',
                    style: TextStyle(
                      color: Colors.white.withAlpha(102),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '-',
                    style: StatLineTypography.scoreDisplay.copyWith(
                      color: Colors.white.withAlpha(77),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      opponentName.length > 12
                          ? opponentName.substring(0, 12)
                          : opponentName,
                      style: TextStyle(
                        color: themWinning
                            ? StatLineColors.pointLost
                            : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
            ],
          ),

          // Set scores row
          if (periods.length > 1 || (periods.isNotEmpty && periods.first.scoreUs > 0))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < periods.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '|',
                          style: TextStyle(
                            color: Colors.white.withAlpha(51),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      '${periods[i].scoreUs}-${periods[i].scoreThem}',
                      style: TextStyle(
                        color: i == periods.length - 1
                            ? Colors.white
                            : Colors.white.withAlpha(153),
                        fontSize: 13,
                        fontWeight: i == periods.length - 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Timeout indicators
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onTimeoutUs,
                    child: _buildTimeoutIndicator(timeoutsUs, maxTimeouts),
                  ),
                ),
                Text(
                  'TO',
                  style: TextStyle(
                    color: Colors.white.withAlpha(102),
                    fontSize: 11,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onTimeoutThem,
                    child: _buildTimeoutIndicator(timeoutsThem, maxTimeouts),
                  ),
                ),
              ],
            ),
          ),
          // Substitution counter
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              onTap: onRecordSub,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Subs: $subsThisSet/$maxSubsPerSet',
                    style: TextStyle(
                      color: _subsColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (onRecordSub != null && subsThisSet < maxSubsPerSet)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '+1',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _subsColor {
    if (subsThisSet >= maxSubsPerSet) return Colors.red;
    if (subsThisSet > maxSubsPerSet * 0.8) return Colors.yellow;
    return Colors.white70;
  }

  Widget _buildTimeoutIndicator(int used, int max) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(max, (i) {
        final isFilled = i < used;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            isFilled ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: isFilled ? Colors.amber : Colors.white38,
          ),
        );
      }),
    );
  }
}
