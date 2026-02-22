import 'package:flutter/material.dart';
import '../../../../domain/models/game_lineup.dart';
import '../../../../domain/models/player.dart';
import '../../../../core/theme/colors.dart';

/// Court-aware lineup panel showing 6 on-court players in volleyball positions
/// and remaining roster players on the bench.
/// 
/// Court positions (front row: 4-3-2, back row: 5-6-1):
/// - Position 1 = RB (Server)
/// - Position 2 = RF
/// - Position 3 = MF
/// - Position 4 = LF
/// - Position 5 = LB
/// - Position 6 = MB
class CourtLineupPanel extends StatelessWidget {
  final int currentRotation;
  final List<GameLineup> lineup;
  final List<Player> roster;
  final String? selectedPlayerId;
  final String? liberoPlayerId;
  final bool liberoIsIn;
  final String? liberoReplacedPlayerId;
  final String? servingTeam;
  final Map<String, String>? lastActions;
  final Map<String, Map<String, dynamic>>? playerStats;
  final ValueChanged<String> onPlayerSelected;
  final VoidCallback onRotateForward;
  final VoidCallback onRotateBackward;

  const CourtLineupPanel({
    super.key,
    required this.currentRotation,
    required this.lineup,
    required this.roster,
    this.selectedPlayerId,
    this.liberoPlayerId,
    this.liberoIsIn = false,
    this.liberoReplacedPlayerId,
    this.servingTeam,
    this.lastActions,
    this.playerStats,
    required this.onPlayerSelected,
    required this.onRotateForward,
    required this.onRotateBackward,
  });

  /// Finds which player is at a given court position based on current rotation.
  /// 
  /// Formula: Player at court position P has startingRotation = ((R + P - 2) % 6) + 1
  /// where R = currentRotation, P = court position (1-6)
  Player? _getPlayerAtPosition(int courtPosition) {
    final startingRot = ((currentRotation + courtPosition - 2) % 6) + 1;
    try {
      final lineupEntry = lineup.firstWhere(
        (l) => l.startingRotation == startingRot,
      );
      return roster.firstWhere((p) => p.id == lineupEntry.playerId);
    } catch (_) {
      return null;
    }
  }

  /// Returns players on the bench (not in the lineup)
  List<Player> _getBenchPlayers() {
    final lineupPlayerIds = lineup.map((l) => l.playerId).toSet();
    return roster.where((p) => !lineupPlayerIds.contains(p.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final benchPlayers = _getBenchPlayers();

    return Container(
      color: const Color(0xFF0E0E0E),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // On-Court Section
            _buildOnCourtSection(),
            
            const Divider(height: 1, color: Color(0xFF333333)),
            
            // Bench Section
            _buildBenchSection(benchPlayers),
          ],
        ),
      ),
    );
  }

  Widget _buildOnCourtSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with rotation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onRotateBackward,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white54,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(26),
                  border: Border.all(color: Colors.white38, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  'R$currentRotation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRotateForward,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'ON COURT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // NET line
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  color: Colors.white24,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'NET',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Front row (positions 4-3-2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCourtPositionChip(4, 'LF'),
              _buildCourtPositionChip(3, 'MF'),
              _buildCourtPositionChip(2, 'RF'),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Back row (positions 5-6-1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCourtPositionChip(5, 'LB'),
              _buildCourtPositionChip(6, 'MB'),
              _buildCourtPositionChip(1, 'RB\nServe'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourtPositionChip(int courtPosition, String posLabel) {
    final player = _getPlayerAtPosition(courtPosition);
    
    if (player == null) {
      return Container(
        width: 100,
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A).withAlpha(128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          posLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final isSelected = player.id == selectedPlayerId;
    final isDesignatedLibero = player.id == liberoPlayerId;
    final isDimmed = liberoIsIn && player.id == liberoReplacedPlayerId;
    final isServer = courtPosition == 1;
    final badgeText = lastActions?[player.id];
    
    // Border color logic
    Color borderColor;
    double borderWidth;
    
    if (isServer && servingTeam == 'us') {
      borderColor = const Color(0xFFFFB300); // Gold/amber for server
      borderWidth = 3.0;
    } else if (isSelected) {
      borderColor = StatLineColors.primaryAccent;
      borderWidth = 2.5;
    } else if (isDesignatedLibero && liberoIsIn) {
      borderColor = StatLineColors.secondaryAccent;
      borderWidth = 2.5;
    } else if (player.positions.contains('L')) {
      borderColor = StatLineColors.secondaryAccent.withAlpha(128);
      borderWidth = 1.5;
    } else {
      borderColor = Colors.white24;
      borderWidth = 1.0;
    }

    final bgColor = isSelected
        ? StatLineColors.primaryAccent.withAlpha(51)
        : const Color(0xFF2A2A2A);

    return Opacity(
      opacity: isDimmed ? 0.35 : 1.0,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onPlayerSelected(player.id),
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Position label (small, top)
                    Text(
                      posLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(128),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Jersey number
                    Text(
                      '#${player.jerseyNumber}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? StatLineColors.primaryAccent
                            : Colors.white,
                      ),
                    ),
                    // Last name
                    Text(
                      player.lastName,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withAlpha(179),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    // Libero badge
                    if (player.positions.contains('L') ||
                        (isDesignatedLibero && liberoIsIn))
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (isDesignatedLibero && liberoIsIn)
                              ? StatLineColors.secondaryAccent.withAlpha(102)
                              : StatLineColors.secondaryAccent.withAlpha(51),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          (isDesignatedLibero && liberoIsIn) ? 'L IN' : 'L',
                          style: const TextStyle(
                            fontSize: 8,
                            color: StatLineColors.secondaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Server volleyball icon
              if (isServer && servingTeam == 'us')
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.sports_volleyball,
                    color: const Color(0xFFFFB300),
                    size: 14,
                  ),
                ),
              // Action badge (last action)
              if (badgeText != null)
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _badgeColor(badgeText),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenchSection(List<Player> benchPlayers) {
    if (benchPlayers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF0E0E0E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BENCH (${benchPlayers.length})',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: benchPlayers.map((player) {
              return _buildBenchChip(player);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchChip(Player player) {
    final isSelected = player.id == selectedPlayerId;
    final isDesignatedLibero = player.id == liberoPlayerId;
    final badgeText = lastActions?[player.id];
    final isLibero = player.positions.contains('L');

    Color borderColor;
    if (isSelected) {
      borderColor = StatLineColors.primaryAccent;
    } else if (isDesignatedLibero && liberoIsIn) {
      borderColor = StatLineColors.secondaryAccent;
    } else if (isLibero) {
      borderColor = StatLineColors.secondaryAccent.withAlpha(77);
    } else {
      borderColor = Colors.white.withAlpha(26);
    }

    final bgColor = isSelected
        ? StatLineColors.primaryAccent.withAlpha(38)
        : const Color(0xFF2A2A2A).withAlpha(153);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => onPlayerSelected(player.id),
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            Container(
              width: 70,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '#${player.jerseyNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? StatLineColors.primaryAccent
                          : Colors.white70,
                    ),
                  ),
                  Text(
                    player.lastName,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withAlpha(128),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (isLibero || (isDesignatedLibero && liberoIsIn))
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: StatLineColors.secondaryAccent.withAlpha(77),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'L',
                        style: TextStyle(
                          fontSize: 7,
                          color: StatLineColors.secondaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Action badge
            if (badgeText != null)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: _badgeColor(badgeText),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _badgeColor(String abbr) {
    const positive = {'K', 'A', 'B', 'BA', 'D', 'AS', 'P3', 'OE'};
    const negative = {'E', 'SE', 'BE', 'DE', 'RE', 'P0', 'AB', 'STE'};
    if (positive.contains(abbr)) return StatLineColors.pointScored;
    if (negative.contains(abbr)) return StatLineColors.pointLost;
    return Colors.grey;
  }
}
