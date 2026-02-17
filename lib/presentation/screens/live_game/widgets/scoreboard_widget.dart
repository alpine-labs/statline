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

  const ScoreboardWidget({
    super.key,
    required this.teamName,
    required this.opponentName,
    required this.scoreUs,
    required this.scoreThem,
    required this.periods,
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
        ],
      ),
    );
  }
}
