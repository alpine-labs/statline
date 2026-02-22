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
  final void Function(String playerOutId, String playerInId)? onSubstitute;
  final ValueChanged<String>? onLiberoIn;
  final VoidCallback? onLiberoOut;

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
    this.onSubstitute,
    this.onLiberoIn,
    this.onLiberoOut,
  });

  /// Finds which player is at a given court position based on current rotation.
  /// 
  /// Formula: Player at court position P has startingRotation = ((R + P - 2) % 6) + 1
  /// where R = currentRotation, P = court position (1-6)
  /// 
  /// When the libero is in, the replaced player is swapped out and the libero
  /// takes their court position.
  Player? _getPlayerAtPosition(int courtPosition) {
    final startingRot = ((currentRotation + courtPosition - 2) % 6) + 1;
    try {
      final lineupEntry = lineup.firstWhere(
        (l) => l.startingRotation == startingRot,
      );
      final normalPlayer = roster.firstWhere((p) => p.id == lineupEntry.playerId);
      // If the libero is in and this position's player was replaced, show the libero
      if (liberoIsIn &&
          liberoReplacedPlayerId == normalPlayer.id &&
          liberoPlayerId != null) {
        return roster.firstWhere((p) => p.id == liberoPlayerId);
      }
      return normalPlayer;
    } catch (_) {
      return null;
    }
  }

  /// Returns players on the bench (not in the lineup).
  /// When the libero is in, the replaced player moves to the bench and the
  /// libero is removed from the bench (since they're on court).
  List<Player> _getBenchPlayers() {
    final lineupPlayerIds = lineup.map((l) => l.playerId).toSet();
    final bench = roster.where((p) => !lineupPlayerIds.contains(p.id)).toList();
    if (liberoIsIn && liberoPlayerId != null && liberoReplacedPlayerId != null) {
      // Remove the libero from bench (they're on court now)
      bench.removeWhere((p) => p.id == liberoPlayerId);
      // Add the replaced player to bench (they're off court now)
      final replaced = roster.where((p) => p.id == liberoReplacedPlayerId);
      if (replaced.isNotEmpty && !bench.any((p) => p.id == liberoReplacedPlayerId)) {
        bench.add(replaced.first);
      }
    }
    return bench;
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
            _buildOnCourtSection(context),
            
            const Divider(height: 1, color: Color(0xFF333333)),
            
            // Bench Section
            _buildBenchSection(context, benchPlayers),
          ],
        ),
      ),
    );
  }

  Widget _buildOnCourtSection(BuildContext context) {
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
              _buildCourtPositionChip(context, 4, 'LF'),
              _buildCourtPositionChip(context, 3, 'MF'),
              _buildCourtPositionChip(context, 2, 'RF'),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Back row (positions 5-6-1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCourtPositionChip(context, 5, 'LB'),
              _buildCourtPositionChip(context, 6, 'MB'),
              _buildCourtPositionChip(context, 1, 'RB\nServe'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourtPositionChip(BuildContext context, int courtPosition, String posLabel) {
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
          onLongPress: () => _showCourtPlayerMenu(
            context, player, courtPosition, isDesignatedLibero,
          ),
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

  Widget _buildBenchSection(BuildContext context, List<Player> benchPlayers) {
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
              return _buildBenchChip(context, player);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchChip(BuildContext context, Player player) {
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
        onLongPress: () => _showBenchPlayerMenu(context, player),
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

  /// Gets court players for substitution picker (the 6 on-court players).
  List<Player> _getCourtPlayers() {
    final players = <Player>[];
    for (int pos = 1; pos <= 6; pos++) {
      final p = _getPlayerAtPosition(pos);
      if (p != null) players.add(p);
    }
    return players;
  }

  /// Long-press menu for a court player: Sub Out, Libero In/Out
  Future<void> _showCourtPlayerMenu(
    BuildContext context,
    Player player,
    int courtPosition,
    bool isDesignatedLibero,
  ) async {
    final items = <PopupMenuEntry<String>>[];
    final isBackRow = const {1, 5, 6}.contains(courtPosition);

    // Libero out (if this IS the libero and is currently on court)
    if (isDesignatedLibero && liberoIsIn) {
      items.add(const PopupMenuItem(
        value: 'libero_out',
        child: Text('Libero Out'),
      ));
    }

    // Libero in: replace this player with the libero (back row only, not the libero themselves)
    if (!isDesignatedLibero &&
        liberoPlayerId != null &&
        !liberoIsIn &&
        isBackRow &&
        !player.positions.contains('L')) {
      items.add(const PopupMenuItem(
        value: 'libero_in',
        child: Text('Libero In (replace)'),
      ));
    }

    // Regular sub out
    if (onSubstitute != null) {
      items.add(const PopupMenuItem(
        value: 'sub_out',
        child: Text('Sub Out'),
      ));
    }

    if (items.isEmpty) return;

    final box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    );
    if (value == null || !context.mounted) return;
    switch (value) {
      case 'libero_out':
        onLiberoOut?.call();
      case 'libero_in':
        onLiberoIn?.call(player.id);
      case 'sub_out':
        _showPickBenchPlayerDialog(context, player);
    }
  }

  /// Long-press menu for a bench player: Sub In, or Libero In (back-row pick)
  Future<void> _showBenchPlayerMenu(BuildContext context, Player player) async {
    final isDesignatedLibero = player.id == liberoPlayerId;
    final items = <PopupMenuEntry<String>>[];

    // Libero on bench and not currently in → offer "Libero In" (pick back-row target)
    if (isDesignatedLibero && !liberoIsIn && onLiberoIn != null) {
      items.add(const PopupMenuItem(
        value: 'libero_in',
        child: Text('Libero In'),
      ));
    }

    // Regular sub (non-libero bench players, or libero as normal sub)
    if (!isDesignatedLibero && onSubstitute != null) {
      items.add(const PopupMenuItem(
        value: 'sub_in',
        child: Text('Sub In'),
      ));
    }

    if (items.isEmpty) return;

    final box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    );
    if (value == null || !context.mounted) return;
    if (value == 'sub_in') {
      _showPickCourtPlayerDialog(context, player);
    } else if (value == 'libero_in') {
      _showPickBackRowPlayerDialog(context);
    }
  }

  /// Dialog to pick which back-row player the libero replaces (triggered from bench).
  void _showPickBackRowPlayerDialog(BuildContext context) {
    final backRowPositions = <int>[1, 5, 6];
    final backRowPlayers = <Player>[];
    for (final pos in backRowPositions) {
      final player = _getPlayerAtPosition(pos);
      if (player != null &&
          player.id != liberoPlayerId &&
          !player.positions.contains('L')) {
        backRowPlayers.add(player);
      }
    }
    if (backRowPlayers.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Replace which back-row player?'),
        children: backRowPlayers.map((p) => SimpleDialogOption(
          onPressed: () {
            Navigator.pop(ctx);
            onLiberoIn?.call(p.id);
          },
          child: Text('#${p.jerseyNumber} ${p.lastName}'),
        )).toList(),
      ),
    );
  }

  /// Dialog to pick which bench player subs in for a court player being subbed out.
  void _showPickBenchPlayerDialog(BuildContext context, Player playerOut) {
    final benchPlayers = _getBenchPlayers()
        .where((p) => p.id != liberoPlayerId)
        .toList();
    if (benchPlayers.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Sub in for #${playerOut.jerseyNumber} ${playerOut.lastName}?'),
        children: benchPlayers.map((p) => SimpleDialogOption(
          onPressed: () {
            Navigator.pop(ctx);
            onSubstitute?.call(playerOut.id, p.id);
          },
          child: Text('#${p.jerseyNumber} ${p.lastName}'),
        )).toList(),
      ),
    );
  }

  /// Dialog to pick which court player the bench player replaces.
  void _showPickCourtPlayerDialog(BuildContext context, Player playerIn) {
    final courtPlayers = _getCourtPlayers()
        .where((p) => p.id != liberoPlayerId)
        .toList();
    if (courtPlayers.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Replace who with #${playerIn.jerseyNumber} ${playerIn.lastName}?'),
        children: courtPlayers.map((p) => SimpleDialogOption(
          onPressed: () {
            Navigator.pop(ctx);
            onSubstitute?.call(p.id, playerIn.id);
          },
          child: Text('#${p.jerseyNumber} ${p.lastName}'),
        )).toList(),
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
