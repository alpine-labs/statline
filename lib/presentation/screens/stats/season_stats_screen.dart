import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/stats_providers.dart';
import '../../providers/team_providers.dart';
import '../../widgets/export_button.dart';
import '../../../domain/models/player_stats.dart';
import '../../../export/csv_exporter.dart';
import '../../../export/share_service.dart';
import 'widgets/stats_table.dart';
import 'player_detail_screen.dart';

class SeasonStatsScreen extends ConsumerStatefulWidget {
  const SeasonStatsScreen({super.key});

  @override
  ConsumerState<SeasonStatsScreen> createState() => _SeasonStatsScreenState();
}

class _SeasonStatsScreenState extends ConsumerState<SeasonStatsScreen> {
  String _activeFilter = 'All';
  String _sortColumn = 'kills';
  bool _sortAscending = false;
  final Set<String> _selectedPlayerIds = {};

  static const _filters = ['All', 'Hitting', 'Serving', 'Defense', 'Blocking'];

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(seasonStatsProvider);
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPlayerIds.isEmpty
            ? 'Season Stats'
            : '${_selectedPlayerIds.length} Selected'),
        actions: [
          if (_selectedPlayerIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Export selected',
              onPressed: () => _exportSeasonCsv(context),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear selection',
              onPressed: () => setState(() => _selectedPlayerIds.clear()),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Leaderboards',
            onPressed: () => context.go('/stats/leaderboard'),
          ),
          ExportButton(
            onExportCsv: () => _exportSeasonCsv(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isActive = filter == _activeFilter;
                return FilterChip(
                  label: Text(filter),
                  selected: isActive,
                  onSelected: (_) => setState(() => _activeFilter = filter),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Stats table
          Expanded(
            child: statsAsync.when(
              data: (stats) {
                if (stats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(77),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No stats available yet',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(128),
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stats will appear after you track a game',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(102),
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                final players = playersAsync.valueOrNull ?? [];
                final columns = _columnsForFilter(_activeFilter);
                final rows = _buildRows(stats, players, columns);

                return StatsTable(
                  columns: columns,
                  rows: rows,
                  sortColumnKey: _sortColumn,
                  sortAscending: _sortAscending,
                  selectedPlayerIds: _selectedPlayerIds,
                  onSort: (key, ascending) {
                    setState(() {
                      _sortColumn = key;
                      _sortAscending = ascending;
                    });
                  },
                  onRowTap: (playerId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PlayerDetailScreen(playerId: playerId),
                      ),
                    );
                  },
                  onRowSelected: (playerId, selected) {
                    setState(() {
                      if (selected) {
                        _selectedPlayerIds.add(playerId);
                      } else {
                        _selectedPlayerIds.remove(playerId);
                      }
                    });
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  List<StatsColumnDef> _columnsForFilter(String filter) {
    const playerCol =
        StatsColumnDef(key: 'player', label: 'Player', isNumeric: false);
    const gpCol = StatsColumnDef(key: 'gp', label: 'GP');

    return switch (filter) {
      'Hitting' => [
          playerCol,
          gpCol,
          const StatsColumnDef(key: 'kills', label: 'K'),
          const StatsColumnDef(key: 'errors', label: 'E'),
          const StatsColumnDef(key: 'totalAttempts', label: 'TA'),
          const StatsColumnDef(key: 'hittingPercentage', label: 'Hit%'),
        ],
      'Serving' => [
          playerCol,
          gpCol,
          const StatsColumnDef(key: 'serviceAces', label: 'SA'),
          const StatsColumnDef(key: 'serviceErrors', label: 'SE'),
          const StatsColumnDef(key: 'serveEfficiency', label: 'SrEff'),
        ],
      'Defense' => [
          playerCol,
          gpCol,
          const StatsColumnDef(key: 'digs', label: 'D'),
          const StatsColumnDef(key: 'receptionErrors', label: 'RE'),
          const StatsColumnDef(key: 'perfectPassPct', label: 'PP%'),
        ],
      'Blocking' => [
          playerCol,
          gpCol,
          const StatsColumnDef(key: 'blockSolos', label: 'BS'),
          const StatsColumnDef(key: 'blockAssists', label: 'BA'),
          const StatsColumnDef(key: 'totalBlocks', label: 'TB'),
        ],
      _ => [
          playerCol,
          gpCol,
          const StatsColumnDef(key: 'kills', label: 'K'),
          const StatsColumnDef(key: 'errors', label: 'E'),
          const StatsColumnDef(key: 'totalAttempts', label: 'TA'),
          const StatsColumnDef(key: 'hittingPercentage', label: 'Hit%'),
          const StatsColumnDef(key: 'assists', label: 'A'),
          const StatsColumnDef(key: 'serviceAces', label: 'SA'),
          const StatsColumnDef(key: 'serviceErrors', label: 'SE'),
          const StatsColumnDef(key: 'digs', label: 'D'),
          const StatsColumnDef(key: 'blockSolos', label: 'BS'),
          const StatsColumnDef(key: 'blockAssists', label: 'BA'),
          const StatsColumnDef(key: 'totalBlocks', label: 'TB'),
          const StatsColumnDef(key: 'perfectPassPct', label: 'PP%'),
          const StatsColumnDef(key: 'serveEfficiency', label: 'SrEff'),
          const StatsColumnDef(key: 'points', label: 'Pts'),
        ],
    };
  }

  List<StatsRowData> _buildRows(
    List<PlayerSeasonStatsModel> stats,
    List<dynamic> players,
    List<StatsColumnDef> columns,
  ) {
    String getPlayerName(String playerId) {
      final p = players.where((p) => p.id == playerId);
      return p.isNotEmpty ? p.first.shortName : playerId;
    }

    final rows = stats.map((s) {
      final totals = s.statsTotals;
      final metrics = s.computedMetrics;
      final bs = (totals['blockSolos'] ?? 0) as num;
      final ba = (totals['blockAssists'] ?? 0) as num;

      final values = <String, dynamic>{
        'player': getPlayerName(s.playerId),
        'playerId': s.playerId,
        'gp': s.gamesPlayed,
        'kills': totals['kills'] ?? 0,
        'errors': totals['errors'] ?? 0,
        'totalAttempts': totals['totalAttempts'] ?? 0,
        'hittingPercentage': metrics['hittingPercentage'] ?? 0.0,
        'assists': totals['assists'] ?? 0,
        'serviceAces': totals['serviceAces'] ?? 0,
        'serviceErrors': totals['serviceErrors'] ?? 0,
        'digs': totals['digs'] ?? 0,
        'blockSolos': bs,
        'blockAssists': ba,
        'totalBlocks': bs + ba,
        'receptionErrors': totals['receptionErrors'] ?? 0,
        'passAttempts': totals['passAttempts'] ?? 0,
        'serveAttempts': totals['serveAttempts'] ?? 0,
        'perfectPassPct': metrics['perfectPassPct'] ?? 0.0,
        'serveEfficiency': metrics['serveEfficiency'] ?? 0.0,
        'points': totals['points'] ?? 0,
      };

      return StatsRowData(playerId: s.playerId, values: values);
    }).toList();

    // Sort
    rows.sort((a, b) {
      final aVal = a.values[_sortColumn];
      final bVal = b.values[_sortColumn];
      if (aVal is num && bVal is num) {
        return _sortAscending
            ? aVal.compareTo(bVal)
            : bVal.compareTo(aVal);
      }
      if (aVal is String && bVal is String) {
        return _sortAscending
            ? aVal.compareTo(bVal)
            : bVal.compareTo(aVal);
      }
      return 0;
    });

    return rows;
  }

  void _exportSeasonCsv(BuildContext context) async {
    var stats = ref.read(seasonStatsProvider).valueOrNull ?? [];
    if (stats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stats to export')),
      );
      return;
    }

    // If players are selected, only export those
    if (_selectedPlayerIds.isNotEmpty) {
      stats = stats
          .where((s) => _selectedPlayerIds.contains(s.playerId))
          .toList();
    }

    try {
      final players = ref.read(playersProvider).valueOrNull ?? [];
      final playerNames = <String, String>{};
      for (final p in players) {
        playerNames[p.id] = p.shortName;
      }

      final csv = CsvExporter.exportSeasonStats(
        stats,
        'volleyball',
        playerNames: playerNames,
      );
      await shareCsvContent(csv, 'season_stats.csv');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
