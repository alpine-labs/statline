import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/game_period.dart';
import '../../../domain/models/play_event.dart';
import '../../../domain/models/player_stats.dart';
import '../../providers/game_providers.dart';
import '../../providers/team_providers.dart';

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

class _GameDetailContent extends ConsumerWidget {
  final Game game;
  final String gameId;

  const _GameDetailContent({required this.game, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Box Score'),
              Tab(text: 'Play-by-Play'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BoxScoreTab(gameId: gameId, game: game),
            _PlayByPlayTab(gameId: gameId),
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

class _PlayByPlayTab extends ConsumerWidget {
  final String gameId;

  const _PlayByPlayTab({required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(gamePlayEventsProvider(gameId));
    final periodsAsync = ref.watch(gamePeriodsProvider(gameId));
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
      },
    );
  }

  Widget _buildEventRow(
      BuildContext context, PlayEvent event, List<dynamic> players) {
    String getPlayerName(String playerId) {
      final p = players.where((p) => p.id == playerId);
      if (p.isNotEmpty) return p.first.shortName;
      return playerId.length > 6 ? playerId.substring(0, 6) : playerId;
    }

    final isPoint = event.result == 'point_us' || event.result == 'point_them';
    final isOurPoint = event.result == 'point_us';
    final isTheirPoint = event.result == 'point_them';

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

    return Container(
      decoration: BoxDecoration(
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
                        .withAlpha(102),
                  ),
            ),
          ),
          // Score
          SizedBox(
            width: 52,
            child: Text(
              '${event.scoreUsAfter}-${event.scoreThemAfter}',
              style: TextStyle(
                fontWeight: isPoint ? FontWeight.bold : FontWeight.normal,
                color: isOurPoint
                    ? StatLineColors.pointScored
                    : isTheirPoint
                        ? StatLineColors.pointLost
                        : null,
              ),
            ),
          ),
          // Player + action
          Expanded(
            child: Text(
              '$playerName — $action',
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Result indicator
          if (isPoint)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        ],
      ),
    );
  }
}
