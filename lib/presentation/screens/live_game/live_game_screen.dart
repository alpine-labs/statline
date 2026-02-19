import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../providers/live_game_providers.dart';
import '../../providers/team_providers.dart';
import '../../providers/game_providers.dart';
import '../../providers/stats_providers.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/play_event.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/scoreboard_widget.dart';
import 'widgets/player_grid.dart';
import 'widgets/action_palette.dart';
import 'widgets/undo_bar.dart';

class LiveGameScreen extends ConsumerStatefulWidget {
  const LiveGameScreen({super.key});

  @override
  ConsumerState<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends ConsumerState<LiveGameScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveGameStateProvider);

    if (!liveState.isActive) {
      return _buildStartGameView(context);
    }

    return Theme(
      data: StatLineTheme.gameMode(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFF0E0E0E),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0E0E0E),
              title: Text(
                'Set ${liveState.currentPeriod?.periodNumber ?? 1}',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                // Entry mode toggle
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'quick', label: Text('Quick')),
                    ButtonSegment(value: 'detailed', label: Text('Detail')),
                  ],
                  selected: {liveState.entryMode},
                  onSelectionChanged: (selected) {
                    ref
                        .read(liveGameStateProvider.notifier)
                        .toggleEntryMode();
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor:
                        WidgetStateProperty.all(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'next_set':
                        ref
                            .read(liveGameStateProvider.notifier)
                            .advancePeriod();
                        break;
                      case 'end_game':
                        _showEndGameDialog(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'next_set',
                      child: Text('Next Set'),
                    ),
                    const PopupMenuItem(
                      value: 'end_game',
                      child: Text('End Game'),
                    ),
                  ],
                ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    // Scoreboard - pinned at top
                    ScoreboardWidget(
                      teamName: liveState.game?.teamId ?? 'Us',
                      opponentName:
                          liveState.game?.opponentName ?? 'Opponent',
                      scoreUs: liveState.scoreUs,
                      scoreThem: liveState.scoreThem,
                      periods: liveState.periods,
                    ),
                    const Divider(height: 1, color: Color(0xFF333333)),

                    // Player grid
                    Expanded(
                      child: PlayerGrid(
                        players: liveState.roster,
                        selectedPlayerId: liveState.selectedPlayerId,
                        onPlayerSelected: (playerId) {
                          ref
                              .read(liveGameStateProvider.notifier)
                              .selectPlayer(playerId);
                        },
                      ),
                    ),

                    // Action palette (visible when player selected)
                    if (liveState.selectedPlayerId != null)
                      ActionPalette(
                        entryMode: liveState.entryMode,
                        onAction: (category, type, result, scoreChange) {
                          _recordAction(
                            context,
                            ref,
                            category,
                            type,
                            result,
                            scoreChange,
                          );
                        },
                      ),
                  ],
                ),

                // Undo bar
                if (liveState.undoStack.isNotEmpty)
                  Positioned(
                    bottom: liveState.selectedPlayerId != null ? 200 : 16,
                    left: 16,
                    right: 16,
                    child: UndoBar(
                      lastEvent: liveState.undoStack.last,
                      players: liveState.roster,
                      onUndo: () {
                        ref
                            .read(liveGameStateProvider.notifier)
                            .undoLastEvent();
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartGameView(BuildContext context) {
    final selectedTeam = ref.watch(selectedTeamProvider);
    final rosterAsync = ref.watch(rosterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Game')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_volleyball,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withAlpha(128),
              ),
              const SizedBox(height: 24),
              Text(
                'Start a New Game',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                selectedTeam != null
                    ? 'Ready to track stats for ${selectedTeam.name}'
                    : 'Select a team first to start a game',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(153),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (selectedTeam != null)
                FilledButton.icon(
                  onPressed: () => _showNewGameDialog(
                      context, selectedTeam, rosterAsync),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Game'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 56),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewGameDialog(
      BuildContext context, dynamic team, AsyncValue<dynamic> rosterAsync) {
    final opponentController = TextEditingController();
    bool isHome = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Game'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: opponentController,
                    decoration: const InputDecoration(
                      labelText: 'Opponent Name',
                      hintText: 'e.g., Rockets VBC',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Home Game'),
                    value: isHome,
                    onChanged: (v) => setDialogState(() => isHome = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (opponentController.text.isEmpty) return;
                    Navigator.pop(context);
                    final now = DateTime.now();
                    final game = Game(
                      id: 'game_${now.millisecondsSinceEpoch}',
                      seasonId: 's1',
                      teamId: team.id,
                      opponentName: opponentController.text,
                      gameDate: now,
                      isHome: isHome,
                      sport: team.sport,
                      gameFormat: {
                        'setsToWin': 3,
                        'maxSets': 5,
                        'pointsPerSet': 25,
                      },
                      status: GameStatus.scheduled,
                      createdAt: now,
                      updatedAt: now,
                    );
                    final roster =
                        rosterAsync.valueOrNull as List<dynamic>? ?? [];
                    final players = roster
                        .map((r) => r.player as Player?)
                        .whereType<Player>()
                        .toList();

                    ref
                        .read(liveGameStateProvider.notifier)
                        .startGame(game, players);
                  },
                  child: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _recordAction(
    BuildContext context,
    WidgetRef ref,
    String category,
    String type,
    String result,
    int scoreChange,
  ) {
    final liveState = ref.read(liveGameStateProvider);
    final playerId = liveState.selectedPlayerId;
    if (playerId == null || liveState.game == null) return;

    int newScoreUs = liveState.scoreUs;
    int newScoreThem = liveState.scoreThem;
    if (scoreChange > 0) {
      newScoreUs += scoreChange;
    } else if (scoreChange < 0) {
      newScoreThem += scoreChange.abs();
    }

    final now = DateTime.now();
    final event = PlayEvent(
      id: 'evt_${now.millisecondsSinceEpoch}',
      gameId: liveState.game!.id,
      periodId: liveState.currentPeriod?.id ?? 'period_1',
      sequenceNumber: liveState.playEvents.length + 1,
      timestamp: now,
      playerId: playerId,
      eventCategory: category,
      eventType: type,
      result: result,
      scoreUsAfter: newScoreUs,
      scoreThemAfter: newScoreThem,
      createdAt: now,
    );

    ref.read(liveGameStateProvider.notifier).recordEvent(event);
  }

  void _showEndGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Game?'),
        content: const Text(
            'Are you sure you want to end this game? Stats will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final liveState = ref.read(liveGameStateProvider);
              final events = List<PlayEvent>.from(liveState.playEvents);
              final periods = List.of(liveState.periods);
              final playerIds =
                  liveState.roster.map((p) => p.id).toList();

              ref.read(liveGameStateProvider.notifier).endGame();
              final endedGame = ref.read(liveGameStateProvider).game;
              if (endedGame != null) {
                ref.read(gamesProvider.notifier).addGame(endedGame);

                // Aggregate stats
                final service =
                    ref.read(statsAggregationServiceProvider);
                await service.aggregateGameStats(
                  game: endedGame,
                  events: events,
                  playerIds: playerIds,
                  periods: periods,
                );

                // Refresh season stats from DB
                await ref
                    .read(seasonStatsProvider.notifier)
                    .loadFromDb(endedGame.seasonId);
              }
              ref.read(liveGameStateProvider.notifier).reset();
            },
            child: const Text('End Game'),
          ),
        ],
      ),
    );
  }
}
