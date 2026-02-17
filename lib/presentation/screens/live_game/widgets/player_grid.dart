import 'package:flutter/material.dart';
import '../../../../domain/models/player.dart';
import '../../../../core/theme/colors.dart';

/// Grid of player buttons for selecting who performed an action.
class PlayerGrid extends StatelessWidget {
  final List<Player> players;
  final String? selectedPlayerId;
  final ValueChanged<String> onPlayerSelected;

  const PlayerGrid({
    super.key,
    required this.players,
    this.selectedPlayerId,
    required this.onPlayerSelected,
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

            return _PlayerButton(
              player: player,
              isSelected: isSelected,
              onTap: () => onPlayerSelected(player.id),
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
  final VoidCallback onTap;

  const _PlayerButton({
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLibero = player.positions.contains('L');

    return Material(
      color: isSelected
          ? StatLineColors.primaryAccent.withAlpha(51)
          : const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? StatLineColors.primaryAccent
                  : isLibero
                      ? StatLineColors.secondaryAccent.withAlpha(128)
                      : Colors.transparent,
              width: isSelected ? 2.5 : 1.5,
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
              if (isLibero)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: StatLineColors.secondaryAccent.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'L',
                    style: TextStyle(
                      fontSize: 10,
                      color: StatLineColors.secondaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
