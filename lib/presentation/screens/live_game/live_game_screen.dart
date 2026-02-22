import 'dart:async';
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
import '../../../domain/sports/volleyball/volleyball_stats.dart';
import '../../../core/constants/sport_config.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/scoreboard_widget.dart';
import 'widgets/player_grid.dart';
import 'widgets/action_palette.dart';
import 'widgets/undo_bar.dart';
import 'widgets/rotation_indicator.dart';

class LiveGameScreen extends ConsumerStatefulWidget {
  const LiveGameScreen({super.key});

  @override
  ConsumerState<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends ConsumerState<LiveGameScreen> {
  Map<String, String> _lastActionBadges = {};
  final Map<String, Timer> _badgeTimers = {};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    for (final timer in _badgeTimers.values) {
      timer.cancel();
    }
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
                      case 'libero_toggle':
                        _handleLiberoToggle(context, ref, liveState);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'next_set',
                      child: Text('Next Set'),
                    ),
                    PopupMenuItem(
                      value: 'libero_toggle',
                      child: Text(
                        liveState.liberoIsIn
                            ? 'Libero Out'
                            : 'Libero In',
                      ),
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
                      timeoutsUs: liveState.timeoutsUs,
                      timeoutsThem: liveState.timeoutsThem,
                      maxTimeouts: liveState.maxTimeoutsPerSet,
                      onTimeoutUs: () => ref
                          .read(liveGameStateProvider.notifier)
                          .callTimeout(true),
                      onTimeoutThem: () => ref
                          .read(liveGameStateProvider.notifier)
                          .callTimeout(false),
                      subsThisSet: liveState.subsThisSet,
                      maxSubsPerSet: liveState.maxSubsPerSet,
                      onRecordSub: () => ref
                          .read(liveGameStateProvider.notifier)
                          .recordSubstitution(),
                      servingTeam: liveState.servingTeam,
                      onToggleServe: () => ref
                          .read(liveGameStateProvider.notifier)
                          .toggleServe(),
                      firstBallSideouts: liveState.firstBallSideouts,
                      totalSideouts: liveState.totalSideouts,
                      sideoutOpportunities: liveState.sideoutOpportunities,
                    ),
                    const Divider(height: 1, color: Color(0xFF333333)),

                    // Rotation indicator
                    RotationIndicator(
                      currentRotation: liveState.currentRotation ?? 1,
                      onRotateForward: () => ref
                          .read(liveGameStateProvider.notifier)
                          .rotateForward(),
                      onRotateBackward: () => ref
                          .read(liveGameStateProvider.notifier)
                          .rotateBackward(),
                      serverName: _getServerDisplayName(liveState),
                    ),
                    const Divider(height: 1, color: Color(0xFF333333)),

                    // Player grid
                    Expanded(
                      child: PlayerGrid(
                        players: liveState.roster,
                        selectedPlayerId: liveState.selectedPlayerId,
                        liberoPlayerId: liveState.liberoPlayerId,
                        liberoIsIn: liveState.liberoIsIn,
                        liberoReplacedPlayerId:
                            liveState.liberoReplacedPlayerId,
                        lastActions: _lastActionBadges,
                        playerStats: _computeAllPlayerStats(liveState),
                        onPlayerSelected: (playerId) {
                          ref
                              .read(liveGameStateProvider.notifier)
                              .selectPlayer(playerId);
                        },
                        onPlayerLongPress: (playerId) {},
                        onSetLibero: (playerId) {
                          ref
                              .read(liveGameStateProvider.notifier)
                              .setLibero(playerId);
                        },
                        onLiberoIn: (replacedPlayerId) {
                          ref
                              .read(liveGameStateProvider.notifier)
                              .liberoIn(replacedPlayerId);
                        },
                        onLiberoOut: () {
                          ref
                              .read(liveGameStateProvider.notifier)
                              .liberoOut();
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

    // Level-aware volleyball defaults
    Map<String, dynamic> format;
    if (team.sport == 'volleyball') {
      format = SportConfig.volleyballFormatForLevel(team.level);
    } else {
      format = SportConfig.defaultFormat(
        Sport.values.firstWhere((s) => s.name == team.sport,
            orElse: () => Sport.volleyball),
      );
    }
    String matchFormat = format['maxSets'] == 5 ? 'bestOf5' : 'bestOf3';

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
                  if (team.sport == 'volleyball') ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: matchFormat,
                      decoration:
                          const InputDecoration(labelText: 'Match Format'),
                      items: const [
                        DropdownMenuItem(
                            value: 'bestOf3',
                            child: Text('Best of 3 (sets to 21)')),
                        DropdownMenuItem(
                            value: 'bestOf5',
                            child: Text('Best of 5 (sets to 25)')),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          matchFormat = v!;
                          if (matchFormat == 'bestOf3') {
                            format = {
                              'setsToWin': 2,
                              'maxSets': 3,
                              'pointsPerSet': 21,
                              'decidingSetPoints': 15,
                              'minPointAdvantage': 2,
                            };
                          } else {
                            format = {
                              'setsToWin': 3,
                              'maxSets': 5,
                              'pointsPerSet': 25,
                              'decidingSetPoints': 15,
                              'minPointAdvantage': 2,
                            };
                          }
                        });
                      },
                    ),
                  ],
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
                        'setsToWin': format['setsToWin'],
                        'maxSets': format['maxSets'],
                        'pointsPerSet': format['pointsPerSet'],
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
                        .startGame(
                          game,
                          players,
                          maxSubsPerSet: team.sport == 'volleyball'
                              ? SportConfig.volleyballSubLimitForLevel(
                                  team.level ?? 'Club')
                              : null,
                        );
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

    // Show action badge on the player button
    final abbr = _actionAbbreviation(type, result);
    _badgeTimers[playerId]?.cancel();
    setState(() {
      _lastActionBadges = {..._lastActionBadges}..[playerId] = abbr;
    });
    _badgeTimers[playerId] = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _lastActionBadges = Map.from(_lastActionBadges)..remove(playerId);
        });
      }
    });
  }

  static String _actionAbbreviation(String type, String result) {
    const map = {
      'kill': 'K', 'attack_error': 'E', 'blocked': 'AB',
      'zero_attack': '0A', 'ace': 'A', 'serve_error': 'SE',
      'serve_in_play': 'SI', 'block_solo': 'B', 'block_assist': 'BA',
      'block_error': 'BE', 'dig': 'D', 'dig_error': 'DE',
      'pass_3': 'P3', 'pass_2': 'P2', 'pass_1': 'P1', 'pass_0': 'P0',
      'overpass': 'OP', 'pass_error': 'RE', 'set_assist': 'AS', 'set_error': 'STE',
      'opp_error': 'OE',
    };
    return map[type] ?? result.substring(0, 1).toUpperCase();
  }

  Map<String, Map<String, dynamic>> _computeAllPlayerStats(LiveGameState liveState) {
    final result = <String, Map<String, dynamic>>{};
    for (final player in liveState.roster) {
      result[player.id] = VolleyballStats.aggregateFromEvents(
        liveState.playEvents,
        playerId: player.id,
      );
    }
    return result;
  }

  String? _getServerDisplayName(LiveGameState liveState) {
    final serverId = ref.read(liveGameStateProvider.notifier).getServerPlayerId();
    if (serverId == null) return null;
    final player = liveState.roster.where((p) => p.id == serverId);
    if (player.isEmpty) return null;
    return '#${player.first.jerseyNumber} ${player.first.lastName}';
  }

  void _handleLiberoToggle(
    BuildContext context,
    WidgetRef ref,
    LiveGameState liveState,
  ) {
    final notifier = ref.read(liveGameStateProvider.notifier);

    if (liveState.liberoIsIn) {
      notifier.liberoOut();
      return;
    }

    if (liveState.liberoPlayerId == null) {
      // No libero designated — prompt user
      final liberoPlayers = liveState.roster
          .where((p) => p.positions.contains('L'))
          .toList();
      if (liberoPlayers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No player with L position on roster')),
        );
        return;
      }
      if (liberoPlayers.length == 1) {
        notifier.setLibero(liberoPlayers.first.id);
      } else {
        showDialog(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Select Libero'),
            children: liberoPlayers
                .map((p) => SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(ctx);
                        notifier.setLibero(p.id);
                      },
                      child: Text('#${p.jerseyNumber} ${p.lastName}'),
                    ))
                .toList(),
          ),
        );
        return;
      }
    }

    // Libero is designated but out — pick a player to replace
    final nonLiberoPlayers = liveState.roster
        .where((p) => p.id != liveState.liberoPlayerId)
        .where((p) => !p.positions.contains('L'))
        .toList();

    if (nonLiberoPlayers.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Replace which player?'),
        children: nonLiberoPlayers
            .map((p) => SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(ctx);
                    notifier.liberoIn(p.id);
                  },
                  child: Text('#${p.jerseyNumber} ${p.lastName}'),
                ))
            .toList(),
      ),
    );
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
