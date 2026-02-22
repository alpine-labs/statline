import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/game_period.dart';
import '../../../domain/models/play_event.dart';
import '../../../domain/models/player_stats.dart';
import '../../providers/game_providers.dart';
import '../../providers/stats_providers.dart';

/// Game Detail Screen with Box Score and Play-by-Play tabs.
class GameDetailScreen extends ConsumerWidget {
  final String gameId;

  const GameDetailScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameId));

    return gameAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Game Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Game Details')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (game) {
        if (game == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Game Details')),
            body: const Center(child: Text('Game not found')),
          );
        }
        return _GameDetailContent(game: game, gameId: gameId);
      },
    );
  }
}

class _GameDetailContent extends ConsumerStatefulWidget {
  final Game game;
  final String gameId;

  const _GameDetailContent({required this.game, required this.gameId});

  @override
  ConsumerState<_GameDetailContent> createState() =>
      _GameDetailContentState();
}

class _GameDetailContentState extends ConsumerState<_GameDetailContent> {
  bool _correctionMode = false;

  void _toggleCorrectionMode() {
    final entering = !_correctionMode;
    setState(() => _correctionMode = entering);

    if (!entering) {
      // Exiting correction mode → trigger score recalculation
      _recalculateScores();
    }
  }

  Future<void> _recalculateScores() async {
    final statsRepo = ref.read(statsRepositoryProvider);
    await statsRepo.recalculateGameScores(widget.gameId);

    // Re-aggregate player game + season stats
    final aggService = ref.read(statsAggregationServiceProvider);
    final gameRepo = ref.read(gameRepositoryProvider);
    final game = await gameRepo.getGame(widget.gameId);
    if (game != null) {
      final events = await statsRepo.getActivePlayEventsForGame(widget.gameId);
      final periods = await gameRepo.getGamePeriods(widget.gameId);
      final playerIds = events
          .where((e) => !e.isOpponent)
          .map((e) => e.playerId)
          .toSet()
          .toList();
      await aggService.aggregateGameStats(
        game: game,
        events: events,
        playerIds: playerIds,
        periods: periods,
      );
    }

    // Invalidate providers to refresh UI
    ref.invalidate(gameDetailProvider(widget.gameId));
    ref.invalidate(gamePeriodsProvider(widget.gameId));
    ref.invalidate(gamePlayEventsProvider(widget.gameId));
    ref.invalidate(gameAllPlayEventsProvider(widget.gameId));
    ref.invalidate(gamePlayerStatsProvider(widget.gameId));
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isWin = game.result == GameResult.win;
    final isLoss = game.result == GameResult.loss;
    final resultLabel = isWin ? 'W' : isLoss ? 'L' : 'T';
    final resultColor = isWin
        ? StatLineColors.pointScored
        : isLoss
            ? StatLineColors.pointLost
            : Theme.of(context).colorScheme.onSurface;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${game.isHome ? "vs" : "@"} ${game.opponentName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  Text(
                    '$resultLabel  ${game.finalScoreUs ?? 0}-${game.finalScoreThem ?? 0}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: resultColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(game.gameDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(153),
                        ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _correctionMode ? Icons.edit_off : Icons.edit,
                color: _correctionMode
                    ? StatLineColors.pointLost
                    : null,
              ),
              tooltip: _correctionMode
                  ? 'Exit Correction Mode'
                  : 'Enter Correction Mode',
              onPressed: _toggleCorrectionMode,
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Box Score'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Play-by-Play'),
                    if (_correctionMode) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: StatLineColors.pointLost.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'EDIT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: StatLineColors.pointLost,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BoxScoreTab(gameId: widget.gameId, game: game),
            _PlayByPlayTab(
              gameId: widget.gameId,
              correctionMode: _correctionMode,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// =============================================================================
// Box Score Tab
// =============================================================================

class _BoxScoreTab extends ConsumerWidget {
  final String gameId;
  final Game game;

  const _BoxScoreTab({required this.gameId, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(gamePeriodsProvider(gameId));
    final playerStatsAsync = ref.watch(gamePlayerStatsProvider(gameId));
    final playersAsync = ref.watch(playersProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Set scores
        periodsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (periods) => _buildSetScores(context, periods),
        ),
        const SizedBox(height: 16),
        // Player stats table
        playerStatsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildEmptyStats(context),
          data: (stats) {
            if (stats.isEmpty) return _buildEmptyStats(context);
            final players = playersAsync.valueOrNull ?? [];
            return _buildPlayerStatsTable(context, stats, players);
          },
        ),
      ],
    );
  }

  Widget _buildSetScores(BuildContext context, List<GamePeriod> periods) {
    if (periods.isEmpty) {
      // Show just the final score from the game model
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${game.finalScoreUs ?? 0} - ${game.finalScoreThem ?? 0}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Scores',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 60),
                ...periods.map((p) => SizedBox(
                      width: 48,
                      child: Center(
                        child: Text(
                          'S${p.periodNumber}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
                const SizedBox(width: 16),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: Text('Final',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Us row
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text('Us',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                ...periods.map((p) => SizedBox(
                      width: 48,
                      child: Center(
                        child: Text(
                          '${p.scoreUs}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: p.scoreUs > p.scoreThem
                                ? StatLineColors.pointScored
                                : null,
                          ),
                        ),
                      ),
                    )),
                const SizedBox(width: 16),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: Text(
                      '${game.finalScoreUs ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: (game.result == GameResult.win)
                            ? StatLineColors.pointScored
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Them row
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text('Them',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                ...periods.map((p) => SizedBox(
                      width: 48,
                      child: Center(
                        child: Text(
                          '${p.scoreThem}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: p.scoreThem > p.scoreUs
                                ? StatLineColors.pointLost
                                : null,
                          ),
                        ),
                      ),
                    )),
                const SizedBox(width: 16),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: Text(
                      '${game.finalScoreThem ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: (game.result == GameResult.loss)
                            ? StatLineColors.pointLost
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStats(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No player stats recorded for this game.'),
        ),
      ),
    );
  }

  Widget _buildPlayerStatsTable(
    BuildContext context,
    List<PlayerGameStatsModel> stats,
    List<dynamic> players,
  ) {
    String getPlayerName(String playerId) {
      final p = players.where((p) => p.id == playerId);
      if (p.isNotEmpty) return p.first.shortName;
      return playerId.substring(0, 6);
    }

    String getJersey(String playerId) {
      final p = players.where((p) => p.id == playerId);
      if (p.isNotEmpty) return '#${p.first.jerseyNumber}';
      return '';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('Player')),
              DataColumn(label: Text('K'), numeric: true),
              DataColumn(label: Text('E'), numeric: true),
              DataColumn(label: Text('TA'), numeric: true),
              DataColumn(label: Text('Hit%')),
              DataColumn(label: Text('A'), numeric: true),
              DataColumn(label: Text('SA'), numeric: true),
              DataColumn(label: Text('SE'), numeric: true),
              DataColumn(label: Text('D'), numeric: true),
              DataColumn(label: Text('BS'), numeric: true),
              DataColumn(label: Text('BA'), numeric: true),
            ],
            rows: stats.map((pgs) {
              final s = pgs.stats;
              final kills = (s['kills'] ?? 0) as num;
              final errors = (s['attack_errors'] ?? s['errors'] ?? 0) as num;
              final ta = (s['attack_attempts'] ?? s['totalAttempts'] ?? 0) as num;
              final hitPct = ta > 0 ? (kills - errors) / ta : 0.0;

              return DataRow(cells: [
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(getPlayerName(pgs.playerId),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(getJersey(pgs.playerId),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(153),
                            )),
                  ],
                )),
                DataCell(Text('$kills')),
                DataCell(Text('$errors')),
                DataCell(Text('$ta')),
                DataCell(Text(_fmtPct(hitPct))),
                DataCell(Text('${s['assists'] ?? 0}')),
                DataCell(Text('${s['aces'] ?? s['serviceAces'] ?? 0}')),
                DataCell(Text('${s['service_errors'] ?? s['serviceErrors'] ?? 0}')),
                DataCell(Text('${s['digs'] ?? 0}')),
                DataCell(Text('${s['block_solos'] ?? s['blockSolos'] ?? 0}')),
                DataCell(Text('${s['block_assists'] ?? s['blockAssists'] ?? 0}')),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _fmtPct(num pct) {
    if (pct == 0) return '---';
    final millis = (pct * 1000).round();
    final neg = millis < 0;
    return '${neg ? "-" : ""}.${millis.abs().toString().padLeft(3, '0')}';
  }
}

// =============================================================================
// Play-by-Play Tab
// =============================================================================

class _PlayByPlayTab extends ConsumerStatefulWidget {
  final String gameId;
  final bool correctionMode;

  const _PlayByPlayTab({
    required this.gameId,
    required this.correctionMode,
  });

  @override
  ConsumerState<_PlayByPlayTab> createState() => _PlayByPlayTabState();
}

class _PlayByPlayTabState extends ConsumerState<_PlayByPlayTab> {
  /// Tracks event IDs pending delete confirmation (two-tap pattern).
  final Set<String> _pendingDeletes = {};

  @override
  Widget build(BuildContext context) {
    // In correction mode, show all events (including deleted)
    final eventsAsync = widget.correctionMode
        ? ref.watch(gameAllPlayEventsProvider(widget.gameId))
        : ref.watch(gamePlayEventsProvider(widget.gameId));
    final periodsAsync = ref.watch(gamePeriodsProvider(widget.gameId));
    final playersAsync = ref.watch(playersProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No play events recorded for this game.'),
            ),
          );
        }

        final periods = periodsAsync.valueOrNull ?? [];
        final players = playersAsync.valueOrNull ?? [];

        // Group events by periodId
        final grouped = <String, List<PlayEvent>>{};
        for (final e in events) {
          grouped.putIfAbsent(e.periodId, () => []).add(e);
        }

        // Build period map for labels
        final periodMap = <String, GamePeriod>{};
        for (final p in periods) {
          periodMap[p.id] = p;
        }

        // Sort period groups by period number
        final sortedPeriodIds = grouped.keys.toList()
          ..sort((a, b) {
            final pa = periodMap[a]?.periodNumber ?? 0;
            final pb = periodMap[b]?.periodNumber ?? 0;
            return pa.compareTo(pb);
          });

        // Collect all active events for insert-position picker
        final activeEvents = events.where((e) => !e.isDeleted).toList();

        final listView = ListView.builder(
          padding: EdgeInsets.only(
            top: 8,
            bottom: widget.correctionMode ? 80 : 8,
          ),
          itemCount: sortedPeriodIds.length,
          itemBuilder: (context, index) {
            final periodId = sortedPeriodIds[index];
            final periodEvents = grouped[periodId]!;
            final period = periodMap[periodId];
            final periodLabel = period != null
                ? 'Set ${period.periodNumber}'
                : 'Set ${index + 1}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sticky set header
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        periodLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (period != null)
                        Text(
                          '${period.scoreUs}-${period.scoreThem}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                // Events
                ...periodEvents.map((event) =>
                    _buildEventRow(context, event, players)),
              ],
            );
          },
        );

        if (!widget.correctionMode) return listView;

        // Correction mode: overlay FAB for inserting events
        return Stack(
          children: [
            listView,
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'insert_event_fab',
                onPressed: () => _showInsertSheet(
                  context,
                  activeEvents,
                  periods,
                  players,
                ),
                tooltip: 'Add Event',
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent(PlayEvent event) async {
    final statsRepo = ref.read(statsRepositoryProvider);
    await statsRepo.softDeleteEventForCorrection(event.id, 'delete');
    // Refresh events
    ref.invalidate(gameAllPlayEventsProvider(widget.gameId));
    ref.invalidate(gamePlayEventsProvider(widget.gameId));
    setState(() => _pendingDeletes.remove(event.id));
  }

  Widget _buildEventRow(
      BuildContext context, PlayEvent event, List<dynamic> players) {
    String getPlayerName(String playerId) {
      final p = players.where((p) => p.id == playerId);
      if (p.isNotEmpty) return p.first.shortName;
      return playerId.length > 6 ? playerId.substring(0, 6) : playerId;
    }

    final isDeleted = event.isDeleted;
    final isPoint = event.result == 'point_us' || event.result == 'point_them';
    final isOurPoint = event.result == 'point_us';
    final isTheirPoint = event.result == 'point_them';
    final isPendingDelete = _pendingDeletes.contains(event.id);

    // Format action label
    final action = event.eventType
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');

    final playerName =
        event.isOpponent ? 'Opponent' : getPlayerName(event.playerId);

    final rowContent = Container(
      decoration: BoxDecoration(
        color: isPendingDelete
            ? StatLineColors.pointLost.withAlpha(25)
            : isDeleted
                ? Theme.of(context).colorScheme.surface.withAlpha(128)
                : null,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withAlpha(51),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Sequence number
          SizedBox(
            width: 28,
            child: Text(
              '${event.sequenceNumber}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(isDeleted ? 51 : 102),
                    decoration:
                        isDeleted ? TextDecoration.lineThrough : null,
                  ),
            ),
          ),
          // Score
          SizedBox(
            width: 52,
            child: Text(
              '${event.scoreUsAfter}-${event.scoreThemAfter}',
              style: TextStyle(
                fontWeight:
                    isPoint && !isDeleted ? FontWeight.bold : FontWeight.normal,
                color: isDeleted
                    ? Theme.of(context).colorScheme.onSurface.withAlpha(76)
                    : isOurPoint
                        ? StatLineColors.pointScored
                        : isTheirPoint
                            ? StatLineColors.pointLost
                            : null,
                decoration: isDeleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          // Player + action
          Expanded(
            child: Text(
              '$playerName — $action',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDeleted
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(76)
                        : null,
                    decoration:
                        isDeleted ? TextDecoration.lineThrough : null,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Deleted label
          if (isDeleted)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: StatLineColors.pointLost.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Deleted',
                style: TextStyle(
                  fontSize: 10,
                  color: StatLineColors.pointLost,
                ),
              ),
            )
          // Result indicator (not shown for deleted)
          else if (isPoint)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isOurPoint
                        ? StatLineColors.pointScored
                        : StatLineColors.pointLost)
                    .withAlpha(38),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isOurPoint ? '+1' : '-1',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isOurPoint
                      ? StatLineColors.pointScored
                      : StatLineColors.pointLost,
                ),
              ),
            ),
          // Delete button in correction mode
          if (widget.correctionMode && !isDeleted) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: Icon(
                  isPendingDelete ? Icons.delete_forever : Icons.delete_outline,
                  color: isPendingDelete
                      ? StatLineColors.pointLost
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                ),
                tooltip: isPendingDelete ? 'Confirm Delete' : 'Delete',
                onPressed: () {
                  if (isPendingDelete) {
                    _deleteEvent(event);
                  } else {
                    setState(() => _pendingDeletes.add(event.id));
                    // Auto-cancel after 3 seconds
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        setState(
                            () => _pendingDeletes.remove(event.id));
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );

    // In correction mode, tapping opens the edit sheet (non-deleted events only)
    if (widget.correctionMode && !isDeleted) {
      return InkWell(
        onTap: () => _showEditSheet(context, event, players),
        child: rowContent,
      );
    }

    return rowContent;
  }

  void _showEditSheet(
      BuildContext context, PlayEvent event, List<dynamic> players) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EventEditSheet(
        event: event,
        gameId: widget.gameId,
        players: players,
        onSaved: () {
          ref.invalidate(gameAllPlayEventsProvider(widget.gameId));
          ref.invalidate(gamePlayEventsProvider(widget.gameId));
        },
      ),
    );
  }

  void _showInsertSheet(
    BuildContext context,
    List<PlayEvent> activeEvents,
    List<GamePeriod> periods,
    List<dynamic> players,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EventInsertSheet(
        gameId: widget.gameId,
        activeEvents: activeEvents,
        periods: periods,
        players: players,
        onSaved: () {
          ref.invalidate(gameAllPlayEventsProvider(widget.gameId));
          ref.invalidate(gamePlayEventsProvider(widget.gameId));
        },
      ),
    );
  }
}

// =============================================================================
// Event Edit Bottom Sheet
// =============================================================================

class _EventEditSheet extends ConsumerStatefulWidget {
  final PlayEvent event;
  final String gameId;
  final List<dynamic> players;
  final VoidCallback onSaved;

  const _EventEditSheet({
    required this.event,
    required this.gameId,
    required this.players,
    required this.onSaved,
  });

  @override
  ConsumerState<_EventEditSheet> createState() => _EventEditSheetState();
}

class _EventEditSheetState extends ConsumerState<_EventEditSheet> {
  late String _selectedPlayerId;
  late String _selectedCategory;
  late String _selectedEventType;
  late String _selectedResult;

  // Available categories and their actions
  static const _categoryActions = {
    'attack': ['kill', 'attack_error', 'attack_attempt'],
    'serve': ['service_ace', 'service_error', 'serve_attempt'],
    'block': ['block_solo', 'block_assist', 'block_error'],
    'defense': ['dig', 'dig_error'],
    'reception': ['reception', 'reception_error', 'shank', 'overpass'],
    'setting': ['assist', 'set_error', 'set_attempt'],
    'scoring': ['point_us', 'point_them'],
  };

  // Default result mapping for actions
  static const _actionResults = {
    'kill': 'point_us',
    'attack_error': 'point_them',
    'attack_attempt': 'rally_continues',
    'service_ace': 'point_us',
    'service_error': 'point_them',
    'serve_attempt': 'rally_continues',
    'block_solo': 'point_us',
    'block_assist': 'point_us',
    'block_error': 'point_them',
    'dig': 'rally_continues',
    'dig_error': 'point_them',
    'reception': 'rally_continues',
    'reception_error': 'point_them',
    'shank': 'point_them',
    'overpass': 'point_them',
    'assist': 'rally_continues',
    'set_error': 'point_them',
    'set_attempt': 'rally_continues',
    'point_us': 'point_us',
    'point_them': 'point_them',
  };

  @override
  void initState() {
    super.initState();
    _selectedPlayerId = widget.event.playerId;
    _selectedCategory = widget.event.eventCategory;
    _selectedEventType = widget.event.eventType;
    _selectedResult = widget.event.result;
  }

  List<String> get _availableActions =>
      _categoryActions[_selectedCategory] ?? [_selectedEventType];

  Future<void> _save() async {
    final statsRepo = ref.read(statsRepositoryProvider);

    // Soft-delete original
    await statsRepo.softDeleteEventForCorrection(widget.event.id, 'edit');

    // Insert corrected event
    final corrected = widget.event.copyWith(
      id: '${widget.event.id}_c${DateTime.now().millisecondsSinceEpoch}',
      playerId: _selectedPlayerId,
      eventCategory: _selectedCategory,
      eventType: _selectedEventType,
      result: _selectedResult,
      metadata: {...widget.event.metadata},
      createdAt: DateTime.now(),
    );
    await statsRepo.insertCorrectionEvent(corrected, widget.event.id);

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final playerItems = widget.players
        .map((p) => DropdownMenuItem<String>(
              value: p.id as String,
              child: Text('${p.shortName} (#${p.jerseyNumber})'),
            ))
        .toList();

    final categoryItems = _categoryActions.keys
        .map((c) => DropdownMenuItem<String>(
              value: c,
              child: Text(c[0].toUpperCase() + c.substring(1)),
            ))
        .toList();

    final actionItems = _availableActions
        .map((a) => DropdownMenuItem<String>(
              value: a,
              child: Text(a.replaceAll('_', ' ')),
            ))
        .toList();

    final resultItems = ['point_us', 'point_them', 'rally_continues']
        .map((r) => DropdownMenuItem<String>(
              value: r,
              child: Text(r.replaceAll('_', ' ')),
            ))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Event',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Player
          DropdownButtonFormField<String>(
            value: playerItems.any((i) => i.value == _selectedPlayerId)
                ? _selectedPlayerId
                : null,
            decoration: const InputDecoration(labelText: 'Player'),
            items: playerItems,
            onChanged: (v) => setState(() => _selectedPlayerId = v!),
          ),
          const SizedBox(height: 12),

          // Category
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: categoryItems,
            onChanged: (v) {
              setState(() {
                _selectedCategory = v!;
                final actions = _availableActions;
                if (!actions.contains(_selectedEventType)) {
                  _selectedEventType = actions.first;
                  _selectedResult =
                      _actionResults[_selectedEventType] ?? 'rally_continues';
                }
              });
            },
          ),
          const SizedBox(height: 12),

          // Action
          DropdownButtonFormField<String>(
            value: _availableActions.contains(_selectedEventType)
                ? _selectedEventType
                : _availableActions.first,
            decoration: const InputDecoration(labelText: 'Action'),
            items: actionItems,
            onChanged: (v) {
              setState(() {
                _selectedEventType = v!;
                _selectedResult =
                    _actionResults[_selectedEventType] ?? 'rally_continues';
              });
            },
          ),
          const SizedBox(height: 12),

          // Result
          DropdownButtonFormField<String>(
            value: _selectedResult,
            decoration: const InputDecoration(labelText: 'Result'),
            items: resultItems,
            onChanged: (v) => setState(() => _selectedResult = v!),
          ),
          const SizedBox(height: 24),

          // Audit trail / correction history
          _CorrectionHistory(eventId: widget.event.id),
          const SizedBox(height: 16),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Correction History (Audit Trail)
// =============================================================================

/// Displays the correction audit trail for an event.
class _CorrectionHistory extends ConsumerWidget {
  final String eventId;

  const _CorrectionHistory({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsRepo = ref.read(statsRepositoryProvider);

    return FutureBuilder<List<PlayEvent>>(
      future: statsRepo.getEventAuditTrail(eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.length <= 1) {
          return const SizedBox.shrink();
        }
        final trail = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Text('Correction History',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...trail.map((e) {
              final reason =
                  e.metadata['correctionReason'] as String? ?? 'original';
              final timestamp = e.metadata['correctedAt'] as String? ??
                  e.metadata['deletedAt'] as String? ??
                  e.createdAt.toIso8601String();
              final dateStr = _formatTimestamp(timestamp);
              final isOriginal = trail.first == e && reason == 'original';
              final isDeleted = e.isDeleted;

              final label = isOriginal
                  ? 'Original'
                  : reason == 'edit'
                      ? 'Edited'
                      : reason == 'delete'
                          ? 'Deleted'
                          : reason == 'insert'
                              ? 'Inserted'
                              : reason;

              final action = e.eventType.replaceAll('_', ' ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isDeleted
                          ? Icons.remove_circle_outline
                          : isOriginal
                              ? Icons.circle_outlined
                              : Icons.edit_outlined,
                      size: 14,
                      color: isDeleted
                          ? StatLineColors.pointLost
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(128),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$label: $action (${e.result.replaceAll('_', ' ')})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              decoration: isDeleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDeleted
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(102)
                                  : null,
                            ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(102),
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// =============================================================================
// Event Insert Bottom Sheet
// =============================================================================

class _EventInsertSheet extends ConsumerStatefulWidget {
  final String gameId;
  final List<PlayEvent> activeEvents;
  final List<GamePeriod> periods;
  final List<dynamic> players;
  final VoidCallback onSaved;

  const _EventInsertSheet({
    required this.gameId,
    required this.activeEvents,
    required this.periods,
    required this.players,
    required this.onSaved,
  });

  @override
  ConsumerState<_EventInsertSheet> createState() => _EventInsertSheetState();
}

class _EventInsertSheetState extends ConsumerState<_EventInsertSheet> {
  late String _selectedPeriodId;
  late int _insertAfterSeq;
  String? _selectedPlayerId;
  String _selectedCategory = 'attack';
  String _selectedEventType = 'kill';
  String _selectedResult = 'point_us';

  @override
  void initState() {
    super.initState();
    // Default to last period, insert at end
    _selectedPeriodId = widget.periods.isNotEmpty
        ? widget.periods.last.id
        : '';
    final periodEvents = widget.activeEvents
        .where((e) => e.periodId == _selectedPeriodId)
        .toList();
    _insertAfterSeq = periodEvents.isNotEmpty
        ? periodEvents.map((e) => e.sequenceNumber).reduce((a, b) => a > b ? a : b)
        : 0;
    _selectedPlayerId =
        widget.players.isNotEmpty ? widget.players.first.id as String : null;
  }

  List<String> get _availableActions =>
      _EventEditSheetState._categoryActions[_selectedCategory] ??
      [_selectedEventType];

  Future<void> _save() async {
    if (_selectedPlayerId == null) return;
    final statsRepo = ref.read(statsRepositoryProvider);

    // Shift existing events after insert position
    await statsRepo.shiftSequenceNumbers(
      widget.gameId,
      _selectedPeriodId,
      _insertAfterSeq,
    );

    final newEvent = PlayEvent(
      id: 'ins_${DateTime.now().millisecondsSinceEpoch}',
      gameId: widget.gameId,
      periodId: _selectedPeriodId,
      sequenceNumber: _insertAfterSeq + 1,
      timestamp: DateTime.now(),
      playerId: _selectedPlayerId!,
      eventCategory: _selectedCategory,
      eventType: _selectedEventType,
      result: _selectedResult,
      scoreUsAfter: 0,
      scoreThemAfter: 0,
      createdAt: DateTime.now(),
    );

    await statsRepo.insertCorrectionEvent(newEvent, null);

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final periodItems = widget.periods
        .map((p) => DropdownMenuItem<String>(
              value: p.id,
              child: Text('Set ${p.periodNumber}'),
            ))
        .toList();

    // Build insert-after position items for the selected period
    final periodEvents = widget.activeEvents
        .where((e) => e.periodId == _selectedPeriodId)
        .toList()
      ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));

    final positionItems = <DropdownMenuItem<int>>[
      const DropdownMenuItem<int>(value: 0, child: Text('Start of set')),
      ...periodEvents.map((e) => DropdownMenuItem<int>(
            value: e.sequenceNumber,
            child: Text('After #${e.sequenceNumber}'),
          )),
    ];

    final playerItems = widget.players
        .map((p) => DropdownMenuItem<String>(
              value: p.id as String,
              child: Text('${p.shortName} (#${p.jerseyNumber})'),
            ))
        .toList();

    final categoryItems = _EventEditSheetState._categoryActions.keys
        .map((c) => DropdownMenuItem<String>(
              value: c,
              child: Text(c[0].toUpperCase() + c.substring(1)),
            ))
        .toList();

    final actionItems = _availableActions
        .map((a) => DropdownMenuItem<String>(
              value: a,
              child: Text(a.replaceAll('_', ' ')),
            ))
        .toList();

    final resultItems = ['point_us', 'point_them', 'rally_continues']
        .map((r) => DropdownMenuItem<String>(
              value: r,
              child: Text(r.replaceAll('_', ' ')),
            ))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Event',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Period
          if (periodItems.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedPeriodId,
              decoration: const InputDecoration(labelText: 'Set'),
              items: periodItems,
              onChanged: (v) {
                setState(() {
                  _selectedPeriodId = v!;
                  final evts = widget.activeEvents
                      .where((e) => e.periodId == _selectedPeriodId)
                      .toList();
                  _insertAfterSeq = evts.isNotEmpty
                      ? evts
                          .map((e) => e.sequenceNumber)
                          .reduce((a, b) => a > b ? a : b)
                      : 0;
                });
              },
            ),
          const SizedBox(height: 12),

          // Insert position
          DropdownButtonFormField<int>(
            value: positionItems.any((i) => i.value == _insertAfterSeq)
                ? _insertAfterSeq
                : (positionItems.isNotEmpty ? positionItems.last.value : 0),
            decoration: const InputDecoration(labelText: 'Insert Position'),
            items: positionItems,
            onChanged: (v) => setState(() => _insertAfterSeq = v ?? 0),
          ),
          const SizedBox(height: 12),

          // Player
          DropdownButtonFormField<String>(
            value: _selectedPlayerId,
            decoration: const InputDecoration(labelText: 'Player'),
            items: playerItems,
            onChanged: (v) => setState(() => _selectedPlayerId = v),
          ),
          const SizedBox(height: 12),

          // Category
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: categoryItems,
            onChanged: (v) {
              setState(() {
                _selectedCategory = v!;
                final actions = _availableActions;
                if (!actions.contains(_selectedEventType)) {
                  _selectedEventType = actions.first;
                  _selectedResult =
                      _EventEditSheetState._actionResults[_selectedEventType] ??
                          'rally_continues';
                }
              });
            },
          ),
          const SizedBox(height: 12),

          // Action
          DropdownButtonFormField<String>(
            value: _availableActions.contains(_selectedEventType)
                ? _selectedEventType
                : _availableActions.first,
            decoration: const InputDecoration(labelText: 'Action'),
            items: actionItems,
            onChanged: (v) {
              setState(() {
                _selectedEventType = v!;
                _selectedResult =
                    _EventEditSheetState._actionResults[_selectedEventType] ??
                        'rally_continues';
              });
            },
          ),
          const SizedBox(height: 12),

          // Result
          DropdownButtonFormField<String>(
            value: _selectedResult,
            decoration: const InputDecoration(labelText: 'Result'),
            items: resultItems,
            onChanged: (v) => setState(() => _selectedResult = v!),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
