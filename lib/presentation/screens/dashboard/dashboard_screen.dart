import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/team_providers.dart';
import '../../providers/game_providers.dart';
import '../../providers/stats_providers.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/sport_icon.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/game.dart';
import '../game_detail/game_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTeam = ref.watch(selectedTeamProvider);
    final activeSeason = ref.watch(activeSeasonProvider);
    final record = ref.watch(seasonRecordProvider);
    final gamesAsync = ref.watch(gamesProvider);
    final statsAsync = ref.watch(seasonStatsProvider);

    if (selectedTeam == null) {
      return _buildEmptyState(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SportIcon(sport: selectedTeam.sport, size: 28),
            const SizedBox(width: 8),
            Text(
              'StatLine',
              style: TextStyle(
                color: StatLineColors.logoGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (activeSeason != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  activeSeason.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Start Game hero card
          _buildStartGameCard(context, selectedTeam.name),
          const SizedBox(height: 16),

          // 2. Season record + streak
          gamesAsync.when(
            data: (games) => _buildRecordCard(context, record, games),
            loading: () => _buildRecordCard(context, record, []),
            error: (_, __) => _buildRecordCard(context, record, []),
          ),
          const SizedBox(height: 16),

          // 2b. Trends / Insights card
          gamesAsync.when(
            data: (games) => statsAsync.when(
              data: (stats) => _buildTrendsCard(context, games, stats, ref),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // 3. Last Game box score
          gamesAsync.when(
            data: (games) {
              final completed = games
                  .where((g) => g.status == GameStatus.completed)
                  .toList()
                ..sort((a, b) => b.gameDate.compareTo(a.gameDate));
              if (completed.isEmpty) return const SizedBox.shrink();
              return _buildLastGameCard(context, completed.first);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // 4. Recent Games
          Text(
            'Recent Games',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          gamesAsync.when(
            data: (games) {
              if (games.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No games yet')),
                  ),
                );
              }
              final recent = games.take(5).toList();
              return Column(
                children:
                    recent.map((game) => _buildGameTile(context, game)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),

          // 5. Team Leaders
          Text(
            'Team Leaders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          statsAsync.when(
            data: (stats) {
              if (stats.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No stats yet')),
                  ),
                );
              }
              return _buildLeaderboard(context, stats, ref);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_volleyball,
                color: StatLineColors.logoGreen),
            const SizedBox(width: 8),
            Text(
              'StatLine',
              style: TextStyle(
                color: StatLineColors.logoGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
                'Welcome to StatLine',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select a team to get started',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(153),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go('/teams'),
                icon: const Icon(Icons.groups),
                label: const Text('Go to Teams'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartGameCard(BuildContext context, String teamName) {
    return Card(
      color: StatLineColors.primaryAccent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/live-game'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Row(
            children: [
              const Icon(Icons.play_circle_filled,
                  size: 48, color: StatLineColors.onPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: StatLineColors.onPrimary.withAlpha(204),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start a new game',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: StatLineColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: StatLineColors.onPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Compute current streak from completed games sorted newest-first.
  String _computeStreak(List<Game> games) {
    final completed = games
        .where((g) => g.status == GameStatus.completed && g.result != null)
        .toList()
      ..sort((a, b) => b.gameDate.compareTo(a.gameDate));
    if (completed.isEmpty) return '';

    final firstResult = completed.first.result!;
    int count = 0;
    for (final game in completed) {
      if (game.result == firstResult) {
        count++;
      } else {
        break;
      }
    }
    if (count < 2) return '';

    switch (firstResult) {
      case GameResult.win:
        return '🔥 W$count';
      case GameResult.loss:
        return 'L$count';
      case GameResult.tie:
        return 'T$count';
    }
  }

  Widget _buildRecordCard(
      BuildContext context, Map<String, int> record, List<Game> games) {
    final wins = record['wins'] ?? 0;
    final losses = record['losses'] ?? 0;
    final ties = record['ties'] ?? 0;
    final streak = _computeStreak(games);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatCard(
                  label: 'Wins',
                  value: '$wins',
                  valueColor: StatLineColors.pointScored,
                  width: 80,
                ),
                Text(
                  '-',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(102),
                      ),
                ),
                StatCard(
                  label: 'Losses',
                  value: '$losses',
                  valueColor: StatLineColors.pointLost,
                  width: 80,
                ),
                if (ties > 0) ...[
                  Text(
                    '-',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(102),
                        ),
                  ),
                  StatCard(
                    label: 'Ties',
                    value: '$ties',
                    width: 80,
                  ),
                ],
              ],
            ),
            if (streak.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                streak,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastGameCard(BuildContext context, Game game) {
    final isWin = game.result == GameResult.win;
    final isLoss = game.result == GameResult.loss;
    final resultLabel = isWin
        ? 'W'
        : isLoss
            ? 'L'
            : 'T';
    final resultColor = isWin
        ? StatLineColors.pointScored
        : isLoss
            ? StatLineColors.pointLost
            : Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last Game', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: resultColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        resultLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: resultColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${game.isHome ? "vs" : "@"} ${game.opponentName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(game.gameDate),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(153),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${game.finalScoreUs ?? 0} - ${game.finalScoreThem ?? 0}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      softWrap: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GameDetailScreen(gameId: game.id, initialTabIndex: 1),
                        ),
                      );
                    },
                    child: const Text('View Game →'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameTile(BuildContext context, dynamic game) {
    final isWin = game.result == GameResult.win;
    final isLoss = game.result == GameResult.loss;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameDetailScreen(gameId: game.id),
            ),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isWin
                ? StatLineColors.pointScored.withAlpha(51)
                : isLoss
                    ? StatLineColors.pointLost.withAlpha(51)
                    : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              isWin
                  ? 'W'
                  : isLoss
                      ? 'L'
                      : 'T',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWin
                    ? StatLineColors.pointScored
                    : isLoss
                        ? StatLineColors.pointLost
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        title: Text(
          '${game.isHome ? "vs" : "@"} ${game.opponentName}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${game.finalScoreUs ?? 0} - ${game.finalScoreThem ?? 0}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Text(
          _formatDate(game.gameDate),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  /// Generate simple insight strings from season stats and game data.
  List<String> _generateInsights(
      List<Game> games, List<dynamic> stats, WidgetRef ref) {
    final insights = <String>[];

    // 1. Win/loss streak check
    final completed = games
        .where((g) => g.status == GameStatus.completed && g.result != null)
        .toList()
      ..sort((a, b) => b.gameDate.compareTo(a.gameDate));
    if (completed.length >= 2) {
      final firstResult = completed.first.result!;
      int streakCount = 0;
      for (final g in completed) {
        if (g.result == firstResult) {
          streakCount++;
        } else {
          break;
        }
      }
      if (streakCount >= 3 && firstResult == GameResult.win) {
        insights.add('🔥 Team is on a $streakCount-game win streak!');
      } else if (streakCount >= 3 && firstResult == GameResult.loss) {
        insights.add('⚠️ Team is on a $streakCount-game losing streak');
      }
    }

    // 2. Service errors check — flag if team total is high
    if (stats.isNotEmpty) {
      final totalServiceErrors = stats.fold<num>(
          0, (sum, s) => sum + ((s.statsTotals['serviceErrors'] ?? 0) as num));
      final totalGames = stats
          .map((s) => s.gamesPlayed as int)
          .fold<int>(0, (a, b) => a > b ? a : b);
      if (totalGames > 0) {
        final errorsPerGame = totalServiceErrors / totalGames;
        if (errorsPerGame > 5) {
          insights.add(
              '📈 Service errors trending up (${errorsPerGame.toStringAsFixed(1)}/game)');
        }
      }
    }

    // 3. Top hitter hitting % dip check
    if (stats.isNotEmpty) {
      final playersAsync = ref.read(playersProvider);
      final players = playersAsync.valueOrNull ?? [];
      String getPlayerName(String playerId) {
        final p = players.where((p) => p.id == playerId);
        return p.isNotEmpty ? p.first.shortName : 'Player';
      }

      final sortedByKills = List.from(stats)
        ..sort((a, b) => ((b.statsTotals['kills'] ?? 0) as num)
            .compareTo((a.statsTotals['kills'] ?? 0) as num));
      if (sortedByKills.isNotEmpty) {
        final topHitter = sortedByKills.first;
        final hitPct =
            (topHitter.computedMetrics['hittingPercentage'] ?? 0) as num;
        if (hitPct < 0.200 && (topHitter.statsTotals['kills'] ?? 0) > 10) {
          insights.add(
              "⚠️ ${getPlayerName(topHitter.playerId)}'s hitting % has dipped recently");
        }
      }
    }

    return insights;
  }

  Widget _buildTrendsCard(BuildContext context, List<Game> games,
      List<dynamic> stats, WidgetRef ref) {
    final insights = _generateInsights(games, stats, ref);
    final displayInsights = insights.isNotEmpty
        ? insights
        : ['📊 Stats looking steady — keep it up!'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...displayInsights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(insight,
                      style: Theme.of(context).textTheme.bodyMedium),
                )),
          ],
        ),
      ),
    );
  }

  /// Returns a trend arrow widget: ▲ green if above average, ▼ red if below.
  Widget _buildTrendArrow(num value, num average) {
    if (average == 0) return const SizedBox.shrink();
    if (value > average) {
      return const Text(' ▲',
          style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12));
    } else if (value < average) {
      return const Text(' ▼',
          style: TextStyle(color: Color(0xFFF44336), fontSize: 12));
    }
    return const Text(' —',
        style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12));
  }

  Widget _buildLeaderboard(
      BuildContext context, List<dynamic> stats, WidgetRef ref) {
    // Top kills
    final sortedByKills = List.from(stats)
      ..sort((a, b) => ((b.statsTotals['kills'] ?? 0) as num)
          .compareTo((a.statsTotals['kills'] ?? 0) as num));
    final topKillers = sortedByKills.take(3).toList();

    // Top hitting %
    final sortedByHitPct = List.from(stats)
      ..sort((a, b) => ((b.computedMetrics['hittingPercentage'] ?? 0) as num)
          .compareTo(
              (a.computedMetrics['hittingPercentage'] ?? 0) as num));
    final topHitters = sortedByHitPct.take(3).toList();

    final playersAsync = ref.watch(playersProvider);
    final players = playersAsync.valueOrNull ?? [];

    String getPlayerName(String playerId) {
      final p = players.where((p) => p.id == playerId);
      return p.isNotEmpty ? p.first.shortName : playerId;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Kills',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...topKillers.map((s) {
              final kills = (s.statsTotals['kills'] ?? 0) as num;
              final avgKills = (s.statsAverages['kills'] ?? 0) as num;
              final gamesPlayed = s.gamesPlayed as int;
              // Compare per-game rate vs average
              final lastGameRate =
                  gamesPlayed > 0 ? kills / gamesPlayed : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        getPlayerName(s.playerId),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${s.statsTotals['kills'] ?? 0}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        _buildTrendArrow(lastGameRate, avgKills),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            Text('Top Hitting %',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...topHitters.map((s) {
              final hitPct =
                  (s.computedMetrics['hittingPercentage'] ?? 0) as num;
              // Compare against league-average baseline of .250
              const avgBaseline = 0.250;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        getPlayerName(s.playerId),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '.${(hitPct * 1000).round().toString().padLeft(3, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        _buildTrendArrow(hitPct, avgBaseline),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
