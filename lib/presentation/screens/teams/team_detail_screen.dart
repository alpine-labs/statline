import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/team_providers.dart';
import '../../providers/game_providers.dart';
import '../../providers/stats_providers.dart';
import '../../../domain/models/team.dart';
import '../../../domain/models/game.dart';
import '../../../core/theme/colors.dart';
import 'player_form_screen.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  final Team team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(seasonRecordProvider);
    final gamesAsync = ref.watch(gamesProvider);

    // Calculate current streak from completed games
    final streak = gamesAsync.whenOrNull(data: (games) {
      final teamGames = games
          .where((g) =>
              g.teamId == widget.team.id &&
              g.status == GameStatus.completed &&
              g.result != null)
          .toList()
        ..sort((a, b) => b.gameDate.compareTo(a.gameDate));
      if (teamGames.isEmpty) return '';
      final firstResult = teamGames.first.result;
      int count = 0;
      for (final g in teamGames) {
        if (g.result == firstResult) {
          count++;
        } else {
          break;
        }
      }
      final prefix = firstResult == GameResult.win
          ? 'W'
          : firstResult == GameResult.loss
              ? 'L'
              : 'T';
      return '$prefix$count';
    });

    final wins = record['wins'] ?? 0;
    final losses = record['losses'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
      ),
      body: Column(
        children: [
          // Overview header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '$wins-$losses',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (streak != null && streak.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: streak.startsWith('W')
                              ? StatLineColors.pointScored.withAlpha(38)
                              : StatLineColors.pointLost.withAlpha(38),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          streak,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: streak.startsWith('W')
                                ? StatLineColors.pointScored
                                : StatLineColors.pointLost,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${widget.team.level} • ${widget.team.gender}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Games'),
              Tab(text: 'Roster'),
              Tab(text: 'Stats'),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _GamesTab(team: widget.team),
                _RosterTab(team: widget.team),
                _StatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Games Tab ────────────────────────────────────────────────────────────────

class _GamesTab extends ConsumerWidget {
  final Team team;

  const _GamesTab({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return gamesAsync.when(
      data: (games) {
        final teamGames = games.where((g) => g.teamId == team.id).toList()
          ..sort((a, b) => b.gameDate.compareTo(a.gameDate));

        if (teamGames.isEmpty) {
          return const Center(child: Text('No games yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 88),
          itemCount: teamGames.length,
          itemBuilder: (context, index) {
            final game = teamGames[index];
            final isWin = game.result == GameResult.win;
            final isCompleted = game.status == GameStatus.completed;
            final borderColor = !isCompleted
                ? Theme.of(context).colorScheme.outline
                : isWin
                    ? StatLineColors.pointScored
                    : StatLineColors.pointLost;

            final scoreUs = game.finalScoreUs ?? 0;
            final scoreThem = game.finalScoreThem ?? 0;
            final resultLabel = isCompleted
                ? game.result == GameResult.win
                    ? 'W'
                    : game.result == GameResult.loss
                        ? 'L'
                        : 'T'
                : '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/game/${game.id}'),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: borderColor, width: 4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.opponentName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(game.gameDate),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(153),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (isCompleted)
                          Text(
                            '$scoreUs-$scoreThem $resultLabel',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isWin
                                      ? StatLineColors.pointScored
                                      : StatLineColors.pointLost,
                                ),
                          )
                        else
                          Text(
                            game.status.name.toUpperCase(),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(128),
                                    ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Roster Tab ───────────────────────────────────────────────────────────────

class _RosterTab extends ConsumerWidget {
  final Team team;

  const _RosterTab({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider);

    return rosterAsync.when(
      data: (roster) {
        final teamRoster = roster.where((r) => r.teamId == team.id).toList()
          ..sort((a, b) {
            return (int.tryParse(a.jerseyNumber) ?? 0)
                .compareTo(int.tryParse(b.jerseyNumber) ?? 0);
          });

        if (teamRoster.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add,
                  size: 64,
                  color:
                      Theme.of(context).colorScheme.primary.withAlpha(102),
                ),
                const SizedBox(height: 16),
                Text(
                  'No players on roster',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerFormScreen(team: team),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Player'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 88),
          itemCount: teamRoster.length,
          itemBuilder: (context, index) {
            final entry = teamRoster[index];
            final player = entry.player;

            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha(51),
                  child: Text(
                    '#${entry.jerseyNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(
                  player?.displayName ?? 'Unknown Player',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(player?.positions.join(', ') ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerFormScreen(
                        team: team,
                        player: player,
                        rosterEntry: entry,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Stats Tab ────────────────────────────────────────────────────────────────

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(seasonStatsProvider);

    return statsAsync.when(
      data: (statsList) {
        if (statsList.isEmpty) {
          return const Center(child: Text('No stats available'));
        }

        int totalKills = 0;
        int totalAces = 0;
        int totalBlocks = 0;
        int totalDigs = 0;

        for (final s in statsList) {
          final totals = s.statsTotals;
          totalKills += (totals['kills'] as num?)?.toInt() ?? 0;
          totalAces += (totals['serviceAces'] as num?)?.toInt() ?? 0;
          totalBlocks += ((totals['blockSolos'] as num?)?.toInt() ?? 0) +
              ((totals['blockAssists'] as num?)?.toInt() ?? 0);
          totalDigs += (totals['digs'] as num?)?.toInt() ?? 0;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Totals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatColumn(label: 'Kills', value: totalKills),
                      _StatColumn(label: 'Aces', value: totalAces),
                      _StatColumn(label: 'Blocks', value: totalBlocks),
                      _StatColumn(label: 'Digs', value: totalDigs),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(153),
                ),
          ),
        ],
      ),
    );
  }
}
