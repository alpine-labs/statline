import 'package:flutter/material.dart';
import '../../../../domain/models/game_lineup.dart';
import '../../../../domain/models/player.dart';
import '../../../../domain/models/roster_entry.dart';

/// Bottom sheet for setting up the starting volleyball lineup.
/// 
/// Allows users to assign 6 players to rotation positions 1-6.
/// Position 1 = right-back (server)
/// Positions proceed clockwise: 2=RF, 3=MF, 4=LF, 5=LB, 6=MB
class LineupSetupSheet extends StatefulWidget {
  final List<RosterEntry> roster;
  final String gameId;

  const LineupSetupSheet({
    super.key,
    required this.roster,
    required this.gameId,
  });

  @override
  State<LineupSetupSheet> createState() => _LineupSetupSheetState();
}

class _LineupSetupSheetState extends State<LineupSetupSheet> {
  // Map rotation position (1-6) to Player
  final Map<int, Player> _lineupPositions = {};
  
  // Currently selected rotation position for assignment
  int? _selectedRotation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = _lineupPositions.length == 6;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(102),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Starting Lineup',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap a position, then tap a player to assign',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_lineupPositions.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _lineupPositions.clear();
                        _selectedRotation = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Court diagram with positions
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Quick start button
                  if (_lineupPositions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: _quickStartLineup,
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Quick Start - Auto Assign Starters'),
                      ),
                    ),
                  
                  // Court positions
                  _buildCourtDiagram(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Available players
                  _buildAvailablePlayers(theme),
                ],
              ),
            ),
          ),
          
          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: isComplete ? _confirmLineup : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Start Game'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtDiagram(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(51),
        ),
      ),
      child: Column(
        children: [
          // Net line
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  color: theme.colorScheme.outline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'NET',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Front row (positions 4, 3, 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPositionSlot(4, 'LF', theme),
              _buildPositionSlot(3, 'MF', theme),
              _buildPositionSlot(2, 'RF', theme),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Back row (positions 5, 6, 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPositionSlot(5, 'LB', theme),
              _buildPositionSlot(6, 'MB', theme),
              _buildPositionSlot(1, 'RB\nServer', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionSlot(int rotation, String label, ThemeData theme) {
    final player = _lineupPositions[rotation];
    final isSelected = _selectedRotation == rotation;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedRotation == rotation) {
            // Deselect
            _selectedRotation = null;
          } else {
            // Select this position for assignment
            _selectedRotation = rotation;
          }
        });
      },
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : player != null
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : player != null
                    ? theme.colorScheme.secondary.withAlpha(128)
                    : theme.colorScheme.outline.withAlpha(77),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (player != null) ...[
              Text(
                '#${player.jerseyNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              Text(
                player.lastName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              Icon(
                Icons.add_circle_outline,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailablePlayers(ThemeData theme) {
    final assignedPlayerIds = _lineupPositions.values.map((p) => p.id).toSet();
    final availablePlayers = widget.roster
        .where((entry) => !assignedPlayerIds.contains(entry.player?.id))
        .toList();
    
    // Sort: starters first, then by jersey number
    availablePlayers.sort((a, b) {
      final aIsStarter = a.role == 'starter' ? 0 : 1;
      final bIsStarter = b.role == 'starter' ? 0 : 1;
      if (aIsStarter != bIsStarter) return aIsStarter.compareTo(bIsStarter);
      
      final aNum = int.tryParse(a.player?.jerseyNumber ?? '') ?? 999;
      final bNum = int.tryParse(b.player?.jerseyNumber ?? '') ?? 999;
      return aNum.compareTo(bNum);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Available Players',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${availablePlayers.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (availablePlayers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'All players assigned! 🎉',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availablePlayers.map((entry) {
              final player = entry.player;
              if (player == null) return const SizedBox.shrink();
              
              final isLibero = entry.isLibero;
              final isStarter = entry.role == 'starter';
              
              return FilterChip(
                selected: false,
                onSelected: _selectedRotation != null
                    ? (_) => _assignPlayer(player)
                    : null,
                avatar: CircleAvatar(
                  backgroundColor: isLibero
                      ? theme.colorScheme.errorContainer
                      : isStarter
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    '${player.jerseyNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLibero
                          ? theme.colorScheme.onErrorContainer
                          : isStarter
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(player.displayName),
                    if (isLibero) ...[
                      const SizedBox(width: 4),
                      Text(
                        'L',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
                backgroundColor: _selectedRotation != null
                    ? theme.colorScheme.secondaryContainer.withAlpha(128)
                    : null,
              );
            }).toList(),
          ),
        if (_selectedRotation != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              color: theme.colorScheme.primaryContainer.withAlpha(128),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap a player to assign to position $_selectedRotation',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _assignPlayer(Player player) {
    if (_selectedRotation == null) return;
    
    setState(() {
      _lineupPositions[_selectedRotation!] = player;
      _selectedRotation = null;
    });
  }

  void _quickStartLineup() {
    // Auto-assign starters in rotation order, skipping libero
    final starters = widget.roster
        .where((entry) => 
            entry.role == 'starter' && 
            entry.isLibero == false &&
            entry.player != null)
        .map((entry) => entry.player!)
        .toList();
    
    // Sort by jersey number
    starters.sort((a, b) =>
        (int.tryParse(a.jerseyNumber) ?? 999).compareTo(
            int.tryParse(b.jerseyNumber) ?? 999));
    
    setState(() {
      _lineupPositions.clear();
      for (int i = 0; i < 6 && i < starters.length; i++) {
        _lineupPositions[i + 1] = starters[i];
      }
      _selectedRotation = null;
    });
    
    if (starters.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only ${starters.length} starters available. Add more players to complete lineup.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _confirmLineup() {
    if (_lineupPositions.length != 6) return;
    
    // Create GameLineup objects
    final lineupList = _lineupPositions.entries.map((entry) {
      final rotation = entry.key;
      final player = entry.value;
      
      return GameLineup(
        id: 'lineup_${widget.gameId}_${player.id}_$rotation',
        gameId: widget.gameId,
        playerId: player.id,
        position: player.positions.isNotEmpty ? player.positions.first : 'Unknown',
        startingRotation: rotation,
        isStarter: true,
        status: 'active',
      );
    }).toList();
    
    // Return lineup to caller
    Navigator.pop(context, lineupList);
  }
}
