import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stats_providers.dart';
import '../../providers/team_providers.dart';
import '../../widgets/stat_card.dart';
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
        ),
        body: TabBarView(
          children: [
            _buildOverview(context, stats, totals, hitPct),
            _buildGameLog(context),
            _buildCharts(context, totals, hitPct),
          ],
        ),
      ),
    );
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
                      value: '.${(hitPct * 1000).round().toString().padLeft(3, '0')}',
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
                    '.${(hitPct * 1000).round().toString().padLeft(3, '0')}'),
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

  Widget _buildGameLog(BuildContext context) {
    // Mock game-by-game data
    final gameLogData = [
      {'game': 'vs Rockets VBC', 'k': 12, 'e': 3, 'ta': 25, 'a': 1, 'sa': 2, 'd': 5},
      {'game': '@ Eagles Club', 'k': 8, 'e': 4, 'ta': 22, 'a': 0, 'sa': 1, 'd': 4},
      {'game': 'vs Panthers VB', 'k': 10, 'e': 2, 'ta': 20, 'a': 1, 'sa': 2, 'd': 6},
      {'game': '@ Wolves Academy', 'k': 9, 'e': 1, 'ta': 18, 'a': 0, 'sa': 1, 'd': 3},
      {'game': 'vs Blaze VBC', 'k': 9, 'e': 2, 'ta': 25, 'a': 1, 'sa': 2, 'd': 4},
    ];

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
            DataColumn(label: Text('A'), numeric: true),
            DataColumn(label: Text('SA'), numeric: true),
            DataColumn(label: Text('D'), numeric: true),
          ],
          rows: gameLogData
              .map((g) => DataRow(cells: [
                    DataCell(Text(g['game'] as String)),
                    DataCell(Text('${g['k']}')),
                    DataCell(Text('${g['e']}')),
                    DataCell(Text('${g['ta']}')),
                    DataCell(Text('${g['a']}')),
                    DataCell(Text('${g['sa']}')),
                    DataCell(Text('${g['d']}')),
                  ]))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCharts(
      BuildContext context, Map<String, dynamic> totals, double hitPct) {
    // Mock game-by-game data for charts
    final gameLabels = ['G1', 'G2', 'G3', 'G4', 'G5'];
    final killsData = [12.0, 8.0, 10.0, 9.0, 9.0];
    final hitPctData = [0.360, 0.182, 0.400, 0.444, 0.280];

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
  }
}
