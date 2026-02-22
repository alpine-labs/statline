import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stats_providers.dart';
import '../../providers/team_providers.dart';
import '../../widgets/stat_card.dart';
import '../../../domain/sports/sport_plugin.dart';
import '../../../domain/stats/stat_calculator.dart';
import '../../../export/csv_exporter.dart';
import '../../../export/share_service.dart';
import '../../../domain/models/player_stats.dart';
import '../game_detail/game_detail_screen.dart';
import 'widgets/line_chart_widget.dart';
import 'widgets/bar_chart_widget.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;

  const PlayerDetailScreen({super.key, required this.playerId});

  SportPlugin? _pluginForRef(WidgetRef ref) {
    final sport = ref.watch(selectedTeamProvider)?.sport;
    if (sport == null) return null;
    try {
      return StatCalculator.getSportPlugin(sport);
    } catch (_) {
      return null;
    }
  }

  String _sportForRef(WidgetRef ref) =>
      ref.read(selectedTeamProvider)?.sport ?? 'volleyball';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(playerDetailProvider(playerId));
    final playersAsync = ref.watch(playersProvider);
    final player = playersAsync.valueOrNull
        ?.where((p) => p.id == playerId)
        .firstOrNull;
    final activeSeason = ref.watch(activeSeasonProvider);
    final plugin = _pluginForRef(ref);

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
            _buildOverview(context, stats, totals, metrics, plugin),
            _buildGameLog(context, gameLogAsync, plugin),
            _buildCharts(context, gameLogAsync, plugin),
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
                  _shareSeasonSummary(context, ref, playerName, stats);
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
                  _shareGameLog(context, ref, playerName, games);
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
    WidgetRef ref,
    String playerName,
    PlayerSeasonStatsModel stats,
  ) async {
    try {
      final sport = _sportForRef(ref);
      final csv = CsvExporter.exportSeasonStats(
        [stats],
        sport,
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
    WidgetRef ref,
    String playerName,
    List<Map<String, dynamic>> games,
  ) async {
    try {
      final sport = _sportForRef(ref);
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
          sport: sport,
          stats: s,
          computedAt: DateTime.now(),
        );
      }).toList();

      final csv = CsvExporter.exportPlayerGameLog(
        gameStats,
        playerName,
        sport,
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

  String _formatStatValue(dynamic value, String? format) {
    if (value == null) return '0';
    switch (format) {
      case 'decimal3':
        final v = (value as num).toDouble();
        if (v == 0) return '---';
        final millis = (v * 1000).round();
        final neg = millis < 0;
        return '${neg ? "-" : ""}.${millis.abs().toString().padLeft(3, '0')}';
      case 'decimal2':
        return (value as num).toStringAsFixed(2);
      case 'percentage':
        return '${((value as num) * 100).toStringAsFixed(1)}%';
      default:
        return '$value';
    }
  }

  dynamic _lookupStat(String key, Map<String, dynamic> totals, Map<String, dynamic> metrics) {
    if (metrics.containsKey(key)) return metrics[key];
    if (totals.containsKey(key)) return totals[key];
    // Computed totalBlocks
    if (key == 'totalBlocks') {
      return ((totals['blockSolos'] ?? 0) as num) + ((totals['blockAssists'] ?? 0) as num);
    }
    return 0;
  }

  Widget _buildOverview(
    BuildContext context,
    dynamic stats,
    Map<String, dynamic> totals,
    Map<String, dynamic> metrics,
    SportPlugin? plugin,
  ) {
    final overviewStats = plugin?.playerOverviewStats ?? [];
    final filterCats = plugin?.statFilterCategories ?? {};

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
                    ...overviewStats.map((col) => StatCard(
                      label: col.label,
                      value: _formatStatValue(
                          _lookupStat(col.key, totals, metrics), col.format),
                      width: 80,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Category breakdown cards from plugin
        ...filterCats.entries.map((entry) {
          final catName = entry.key;
          final catKeys = entry.value;
          // Find matching StatColumns from seasonStatsColumns
          final columns = plugin?.seasonStatsColumns
              .where((c) => catKeys.contains(c.key))
              .toList() ?? [];
          if (columns.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...columns.map((col) => _statRow(
                      context,
                      col.label,
                      _formatStatValue(
                          _lookupStat(col.key, totals, metrics), col.format),
                    )),
                  ],
                ),
              ),
            ),
          );
        }),
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

  Widget _buildGameLog(
      BuildContext context,
      AsyncValue<List<Map<String, dynamic>>> gameLogAsync,
      SportPlugin? plugin,
  ) {
    final logColumns = plugin?.gameLogColumns ?? [];

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
              columns: [
                const DataColumn(label: Text('Game')),
                ...logColumns.map((c) => DataColumn(
                  label: Text(c.shortLabel),
                  numeric: c.format != 'decimal3',
                )),
              ],
              rows: games.map((row) {
                final s = _parseStats(row);
                final opponent = row['opponent_name'] as String? ?? '?';
                final rowGameId = row['game_id'] as String?;
                return DataRow(
                  cells: [
                    DataCell(Text(opponent)),
                    ...logColumns.map((c) {
                      final val = s[c.key] ?? s[_altKey(c.key)] ?? 0;
                      return DataCell(Text(_formatStatValue(val, c.format)));
                    }),
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

  /// Map season-stat keys to game-stat alternate keys used in computed stats
  String _altKey(String key) => switch (key) {
    'errors' => 'attack_errors',
    'totalAttempts' => 'attack_attempts',
    'serviceAces' => 'aces',
    'hittingPercentage' => 'hitting_pct',
    _ => key,
  };

  Widget _buildCharts(
      BuildContext context,
      AsyncValue<List<Map<String, dynamic>>> gameLogAsync,
      SportPlugin? plugin,
  ) {
    final charts = plugin?.trendCharts ?? [];
    if (charts.isEmpty) {
      return const Center(child: Text('No chart definitions for this sport.'));
    }

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

        final gameLabels = games.map((row) {
          final opponent = row['opponent_name'] as String? ?? '?';
          return opponent.length > 6 ? opponent.substring(0, 6) : opponent;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (int i = 0; i < charts.length; i++) ...[
              if (i > 0) const SizedBox(height: 24),
              _buildTrendChart(charts[i], games, gameLabels),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTrendChart(
    TrendChart chart,
    List<Map<String, dynamic>> games,
    List<String> labels,
  ) {
    final data = games.map((row) {
      final s = _parseStats(row);
      final val = s[chart.statKey] ?? s[_altKey(chart.statKey)] ?? 0;
      return (val as num).toDouble();
    }).toList();

    if (chart.isBar) {
      return BarChartWidget(title: chart.title, labels: labels, values: data);
    }
    return LineChartWidget(title: chart.title, xLabels: labels, dataPoints: data);
  }
}
