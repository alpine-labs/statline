import 'package:flutter/material.dart';
import '../../../../domain/models/player.dart';
import '../../../../core/theme/colors.dart';
import '../../../../domain/sports/volleyball/volleyball_stats.dart';
import 'action_palette.dart';

/// Grid of player buttons for selecting who performed an action.
class PlayerGrid extends StatelessWidget {
  final List<Player> players;
  final String? selectedPlayerId;
  final ValueChanged<String> onPlayerSelected;
  final String? liberoPlayerId;
  final bool liberoIsIn;
  final ValueChanged<String>? onSetLibero;
  final ValueChanged<String>? onLiberoIn;
  final VoidCallback? onLiberoOut;
  final String? liberoReplacedPlayerId;
  final Map<String, String>? lastActions;
  final Map<String, Map<String, dynamic>>? playerStats;
  final ValueChanged<String>? onPlayerLongPress;

  const PlayerGrid({
    super.key,
    required this.players,
    this.selectedPlayerId,
    required this.onPlayerSelected,
    this.liberoPlayerId,
    this.liberoIsIn = false,
    this.onSetLibero,
    this.onLiberoIn,
    this.onLiberoOut,
    this.liberoReplacedPlayerId,
    this.lastActions,
    this.playerStats,
    this.onPlayerLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const Center(
        child: Text(
          'No players on roster',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            final isSelected = player.id == selectedPlayerId;
            final isDesignatedLibero = player.id == liberoPlayerId;
            final isDimmed =
                liberoIsIn && player.id == liberoReplacedPlayerId;

            final badgeText = lastActions?[player.id];
            final stats = playerStats?[player.id];

            return _PlayerButton(
              player: player,
              isSelected: isSelected,
              isDesignatedLibero: isDesignatedLibero,
              liberoIsIn: liberoIsIn,
              isDimmed: isDimmed,
              onTap: () => onPlayerSelected(player.id),
              onSetLibero: onSetLibero,
              onLiberoIn: onLiberoIn,
              onLiberoOut: onLiberoOut,
              canBeLibero: player.positions.contains('L'),
              badgeText: badgeText,
              playerStats: stats,
              onPlayerLongPress: onPlayerLongPress != null
                  ? () => onPlayerLongPress!(player.id)
                  : null,
            );
          },
        );
      },
    );
  }
}

class _PlayerButton extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final bool isDesignatedLibero;
  final bool liberoIsIn;
  final bool isDimmed;
  final bool canBeLibero;
  final VoidCallback onTap;
  final ValueChanged<String>? onSetLibero;
  final ValueChanged<String>? onLiberoIn;
  final VoidCallback? onLiberoOut;
  final String? badgeText;
  final Map<String, dynamic>? playerStats;
  final VoidCallback? onPlayerLongPress;

  const _PlayerButton({
    required this.player,
    required this.isSelected,
    this.isDesignatedLibero = false,
    this.liberoIsIn = false,
    this.isDimmed = false,
    this.canBeLibero = false,
    required this.onTap,
    this.onSetLibero,
    this.onLiberoIn,
    this.onLiberoOut,
    this.badgeText,
    this.playerStats,
    this.onPlayerLongPress,
  });

  void _showContextMenu(BuildContext context, Offset position) {
    final items = <PopupMenuEntry<String>>[];

    if (canBeLibero && !isDesignatedLibero) {
      items.add(const PopupMenuItem(
        value: 'set_libero',
        child: Text('Set as Libero'),
      ));
    }

    if (isDesignatedLibero && liberoIsIn) {
      items.add(const PopupMenuItem(
        value: 'libero_out',
        child: Text('Libero Out'),
      ));
    }

    if (!isDesignatedLibero && !canBeLibero) {
      items.add(const PopupMenuItem(
        value: 'libero_in',
        child: Text('Libero In (replace this player)'),
      ));
    }

    if (items.isEmpty) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'set_libero':
          onSetLibero?.call(player.id);
        case 'libero_in':
          onLiberoIn?.call(player.id);
        case 'libero_out':
          onLiberoOut?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLibero = player.positions.contains('L');
    final opacity = isDimmed ? 0.35 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: isSelected
            ? StatLineColors.primaryAccent.withAlpha(51)
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: () {
                  if (onPlayerLongPress != null && playerStats != null) {
                    _showStatsPeek(context);
                  } else if (canBeLibero || isDesignatedLibero || (!player.positions.contains('L'))) {
                    final box = context.findRenderObject() as RenderBox;
                    final position = box.localToGlobal(Offset.zero);
                    _showContextMenu(context, position);
                  }
                },
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? StatLineColors.primaryAccent
                        : (isDesignatedLibero && liberoIsIn)
                            ? StatLineColors.secondaryAccent
                            : isLibero
                                ? StatLineColors.secondaryAccent.withAlpha(128)
                                : Colors.transparent,
                    width: (isDesignatedLibero && liberoIsIn) ? 2.5 : isSelected ? 2.5 : 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${player.jerseyNumber}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? StatLineColors.primaryAccent
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      player.lastName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withAlpha(179),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (isLibero || isDesignatedLibero)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: (isDesignatedLibero && liberoIsIn)
                              ? StatLineColors.secondaryAccent.withAlpha(102)
                              : StatLineColors.secondaryAccent.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (isDesignatedLibero && liberoIsIn) ? 'L IN' : 'L',
                          style: const TextStyle(
                            fontSize: 10,
                            color: StatLineColors.secondaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (badgeText != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _badgeColor(badgeText!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        fontSize: 10,
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

  Color _badgeColor(String abbr) {
    const positive = {'K', 'A', 'B', 'BA', 'D', 'AS', 'P3', 'OE'};
    const negative = {'E', 'SE', 'BE', 'DE', 'RE', 'P0', 'AB', 'STE'};
    if (positive.contains(abbr)) return StatLineColors.pointScored;
    if (negative.contains(abbr)) return StatLineColors.pointLost;
    return Colors.grey;
  }

  void _showStatsPeek(BuildContext context) {
    final stats = playerStats!;
    final kills = stats['kills'] ?? 0;
    final errors = stats['attack_errors'] ?? 0;
    final attempts = stats['attack_attempts'] ?? 0;
    final hitPct = stats['hitting_pct'] ?? 0.0;
    final assists = stats['assists'] ?? 0;
    final aces = stats['aces'] ?? 0;
    final digs = stats['digs'] ?? 0;
    final blocks = stats['total_blocks'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: Text(
          '#${player.jerseyNumber} ${player.lastName}',
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: DefaultTextStyle(
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('K: $kills   E: $errors   TA: $attempts   Hit%: ${hitPct is double ? hitPct.toStringAsFixed(3) : hitPct}'),
              const SizedBox(height: 4),
              Text('A: $assists   SA: $aces   D: $digs   B: $blocks'),
            ],
          ),
        ),
      ),
    );
  }
}
