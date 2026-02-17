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
            const Text('StatLine'),
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
          // Team name
          Text(
            selectedTeam.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Season record
          _buildRecordCard(context, record),
          const SizedBox(height: 16),

          // New Game button
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/live-game'),
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text('New Game', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 24),

          // Recent games
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

          // Leaderboard snapshot
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
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('StatLine'),
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
                'Create a team to get started tracking your stats.',
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
                icon: const Icon(Icons.add),
                label: const Text('Create Team'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, Map<String, int> record) {
    final wins = record['wins'] ?? 0;
    final losses = record['losses'] ?? 0;
    final ties = record['ties'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(102),
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
      ),
    );
  }

  Widget _buildGameTile(BuildContext context, dynamic game) {
    final isWin = game.result == GameResult.win;
    final isLoss = game.result == GameResult.loss;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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
            ...topKillers.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(getPlayerName(s.playerId)),
                      Text('${s.statsTotals['kills'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Text('Top Hitting %',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...topHitters.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(getPlayerName(s.playerId)),
                      Text(
                        '.${((s.computedMetrics['hittingPercentage'] ?? 0) * 1000).round().toString().padLeft(3, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
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
