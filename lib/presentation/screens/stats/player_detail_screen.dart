import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stats_providers.dart';
import '../../providers/team_providers.dart';
import '../../widgets/stat_card.dart';
import '../../../export/csv_exporter.dart';
import '../../../export/share_service.dart';
import '../../../domain/models/player_stats.dart';
import '../game_detail/game_detail_screen.dart';
import 'widgets/line_chart_widget.dart';
import 'widgets/bar_chart_widget.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;

  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(playerDetailProvider(playerId));
    final playersAsync = ref.watch(playersProvider);
    final player = playersAsync.valueOrNull
        ?.where((p) => p.id == playerId)
        .firstOrNull;
    final activeSeason = ref.watch(activeSeasonProvider);

    // Fetch game log when we have an active season
    final gameLogAsync = activeSeason != null
        ? ref.watch(playerGameLogProvider(
            (playerId: playerId, seasonId: activeSeason.id)))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    if (stats == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Stats')),
        body: const Center(child: Text('No stats available for this player')),
      );
    }

    final totals = stats.statsTotals;
    final metrics = stats.computedMetrics;
    final hitPct = (metrics['hittingPercentage'] ?? 0.0) as double;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player?.displayName ?? 'Player',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (player != null)
                Text(
                  '#${player.jerseyNumber} • ${player.positions.join(", ")}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Game Log'),
              Tab(text: 'Charts'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Share',
              onPressed: () => _showShareSheet(
                context,
                ref,
                player?.displayName ?? 'Player',
                stats,
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildOverview(context, stats, totals, hitPct),
            _buildGameLog(context, gameLogAsync),
            _buildCharts(context, gameLogAsync),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(
    BuildContext context,
    WidgetRef ref,
    String playerName,
    PlayerSeasonStatsModel stats,
  ) {
    final activeSeason = ref.read(activeSeasonProvider);
    final gameLogAsync = activeSeason != null
        ? ref.read(playerGameLogProvider(
            (playerId: playerId, seasonId: activeSeason.id)))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Share Stats',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Season Summary'),
                subtitle: const Text('Export season totals as CSV'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareSeasonSummary(context, playerName, stats);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Game Log'),
                subtitle: const Text('Export game-by-game stats as CSV'),
                enabled: gameLogAsync.valueOrNull?.isNotEmpty ?? false,
                onTap: () {
                  Navigator.pop(ctx);
                  final games = gameLogAsync.valueOrNull ?? [];
                  _shareGameLog(context, playerName, games);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _shareSeasonSummary(
    BuildContext context,
    String playerName,
    PlayerSeasonStatsModel stats,
  ) async {
    try {
      final csv = CsvExporter.exportSeasonStats(
        [stats],
        'volleyball',
        playerNames: {stats.playerId: playerName},
      );
      final fileName =
          '${playerName.replaceAll(' ', '_')}_season_stats.csv';
      await shareCsvContent(csv, fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _shareGameLog(
    BuildContext context,
    String playerName,
    List<Map<String, dynamic>> games,
  ) async {
    try {
      final gameStats = games.map((row) {
        final raw = row['stats'];
        Map<String, dynamic> s;
        if (raw is String) {
          s = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        } else if (raw is Map) {
          s = Map<String, dynamic>.from(raw);
        } else {
          s = {};
        }
        return PlayerGameStatsModel(
          id: row['id'] as String? ?? '',
          gameId: row['game_id'] as String? ?? '',
          playerId: playerId,
          sport: 'volleyball',
          stats: s,
          computedAt: DateTime.now(),
        );
      }).toList();

      final csv = CsvExporter.exportPlayerGameLog(
        gameStats,
        playerName,
        'volleyball',
      );
      final fileName =
          '${playerName.replaceAll(' ', '_')}_game_log.csv';
      await shareCsvContent(csv, fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Widget _buildOverview(
    BuildContext context,
    dynamic stats,
    Map<String, dynamic> totals,
    double hitPct,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Season Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatCard(
                      label: 'Games',
                      value: '${stats.gamesPlayed}',
                      width: 80,
                    ),
                    StatCard(
                      label: 'Kills',
                      value: '${totals['kills'] ?? 0}',
                      width: 80,
                    ),
                    StatCard(
                      label: 'Hit%',
                      value: (totals['totalAttempts'] as num?) == 0 ? '---' : '.${(hitPct * 1000).round().toString().padLeft(3, '0')}',
                      width: 80,
                    ),
                    StatCard(
                      label: 'Assists',
                      value: '${totals['assists'] ?? 0}',
                      width: 80,
                    ),
                    StatCard(
                      label: 'Aces',
                      value: '${totals['serviceAces'] ?? 0}',
                      width: 80,
                    ),
                    StatCard(
                      label: 'Digs',
                      value: '${totals['digs'] ?? 0}',
                      width: 80,
                    ),
                    StatCard(
                      label: 'Blocks',
                      value: '${((totals['blockSolos'] ?? 0) as num) + ((totals['blockAssists'] ?? 0) as num)}',
                      width: 80,
                    ),
                    StatCard(
                      label: 'Points',
                      value: '${totals['points'] ?? 0}',
                      width: 80,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Hitting breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hitting Breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _statRow(context, 'Kills', '${totals['kills'] ?? 0}'),
                _statRow(context, 'Errors', '${totals['errors'] ?? 0}'),
                _statRow(
                    context, 'Total Attempts', '${totals['totalAttempts'] ?? 0}'),
                _statRow(context, 'Hitting %',
                    (totals['totalAttempts'] as num?) == 0 ? '---' : '.${(hitPct * 1000).round().toString().padLeft(3, '0')}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Serving breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Serving',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _statRow(
                    context, 'Service Aces', '${totals['serviceAces'] ?? 0}'),
                _statRow(context, 'Service Errors',
                    '${totals['serviceErrors'] ?? 0}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _parseStats(Map<String, dynamic> row) {
    final raw = row['stats'];
    if (raw is String) return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  String _formatHitPct(Map<String, dynamic> s) {
    final ta = (s['attack_attempts'] ?? s['totalAttempts'] ?? 0) as num;
    if (ta == 0) return '---';
    final pct = (s['hitting_pct'] ?? s['hittingPercentage'] ??
        (((s['kills'] ?? 0) as num) - ((s['attack_errors'] ?? s['errors'] ?? 0) as num)) / ta) as num;
    final millis = (pct * 1000).round();
    final neg = millis < 0;
    return '${neg ? "-" : ""}.${millis.abs().toString().padLeft(3, '0')}';
  }

  Widget _buildGameLog(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> gameLogAsync) {
    return gameLogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading game log: $e')),
      data: (games) {
        if (games.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No games tracked yet.\nTrack a game to see the game log here.',
                  textAlign: TextAlign.center),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Game')),
                DataColumn(label: Text('K'), numeric: true),
                DataColumn(label: Text('E'), numeric: true),
                DataColumn(label: Text('TA'), numeric: true),
                DataColumn(label: Text('Hit%')),
                DataColumn(label: Text('A'), numeric: true),
                DataColumn(label: Text('SA'), numeric: true),
                DataColumn(label: Text('D'), numeric: true),
              ],
              rows: games.map((row) {
                final s = _parseStats(row);
                final opponent = row['opponent_name'] as String? ?? '?';
                final rowGameId = row['game_id'] as String?;
                return DataRow(
                  cells: [
                    DataCell(Text(opponent)),
                    DataCell(Text('${s['kills'] ?? 0}')),
                    DataCell(Text('${s['attack_errors'] ?? s['errors'] ?? 0}')),
                    DataCell(Text('${s['attack_attempts'] ?? s['totalAttempts'] ?? 0}')),
                    DataCell(Text(_formatHitPct(s))),
                    DataCell(Text('${s['assists'] ?? 0}')),
                    DataCell(Text('${s['aces'] ?? s['serviceAces'] ?? 0}')),
                    DataCell(Text('${s['digs'] ?? 0}')),
                  ],
                  onSelectChanged: rowGameId != null
                      ? (_) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GameDetailScreen(gameId: rowGameId),
                            ),
                          );
                        }
                      : null,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharts(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> gameLogAsync) {
    return gameLogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading chart data: $e')),
      data: (games) {
        if (games.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No games tracked yet.\nTrack a game to see charts here.',
                  textAlign: TextAlign.center),
            ),
          );
        }

        final gameLabels = <String>[];
        final killsData = <double>[];
        final hitPctData = <double>[];

        for (final row in games) {
          final s = _parseStats(row);
          final opponent = row['opponent_name'] as String? ?? '?';
          // Shorten label: first 6 chars
          gameLabels.add(opponent.length > 6 ? opponent.substring(0, 6) : opponent);
          killsData.add(((s['kills'] ?? 0) as num).toDouble());
          final ta = (s['attack_attempts'] ?? s['totalAttempts'] ?? 0) as num;
          if (ta == 0) {
            hitPctData.add(0.0);
          } else {
            final pct = s['hitting_pct'] ?? s['hittingPercentage'] ??
                (((s['kills'] ?? 0) as num) - ((s['attack_errors'] ?? s['errors'] ?? 0) as num)) / ta;
            hitPctData.add((pct as num).toDouble());
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LineChartWidget(
              title: 'Hitting % Over Games',
              xLabels: gameLabels,
              dataPoints: hitPctData,
            ),
            const SizedBox(height: 24),
            BarChartWidget(
              title: 'Kills Per Game',
              labels: gameLabels,
              values: killsData,
            ),
          ],
        );
      },
    );
  }
}
