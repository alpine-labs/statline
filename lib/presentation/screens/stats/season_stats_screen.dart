import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/stats_providers.dart';
import '../../providers/team_providers.dart';
import '../../widgets/export_button.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/player_stats.dart';
import '../../../export/csv_exporter.dart';
import '../../../export/share_service.dart';
import '../../../export/stats_email_formatter.dart';
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

  static const _filters = ['All', 'Hitting', 'Serving', 'Defense', 'Blocking', 'Passing'];

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(seasonStatsProvider);
    final playersAsync = ref.watch(playersProvider);
    final selectedTeam = ref.watch(selectedTeamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPlayerIds.isEmpty
            ? (selectedTeam != null ? '${selectedTeam.name} Stats' : 'Season Stats')
            : '${_selectedPlayerIds.length} Selected'),
        actions: [
          if (_selectedPlayerIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.email_outlined),
              tooltip: 'Email stats to players',
              onPressed: () => _showEmailSheet(context),
            ),
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
                  onSelectAll: (selectAll) {
                    setState(() {
                      if (selectAll) {
                        _selectedPlayerIds.addAll(
                          rows.map((r) => r.playerId),
                        );
                      } else {
                        _selectedPlayerIds.clear();
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
      'Passing' => [
          playerCol,
          gpCol,
          const StatsColumnDef(key: 'passAttempts', label: 'Rec'),
          const StatsColumnDef(key: 'passRating', label: 'PR'),
          const StatsColumnDef(key: 'perfectPassPct', label: 'PP%'),
          const StatsColumnDef(key: 'receptionErrors', label: 'RE'),
          const StatsColumnDef(key: 'overpasses', label: 'OP'),
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
        'passRating': metrics['pass_rating_avg'] ?? 0.0,
        'overpasses': totals['overpasses'] ?? 0,
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

  void _showEmailSheet(BuildContext context) {
    final players = ref.read(playersProvider).valueOrNull ?? [];
    final stats = ref.read(seasonStatsProvider).valueOrNull ?? [];

    final selectedPlayers = players
        .where((p) => _selectedPlayerIds.contains(p.id))
        .toList();

    if (selectedPlayers.isEmpty) return;

    final playersWithEmail =
        selectedPlayers.where((p) => p.email != null && p.email!.isNotEmpty).toList();
    final playersWithoutEmail =
        selectedPlayers.where((p) => p.email == null || p.email!.isEmpty).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurface.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Email Stats',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${playersWithEmail.length} of ${selectedPlayers.length} players have an email on file',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurface.withAlpha(153),
                    ),
              ),
              const SizedBox(height: 8),
              if (playersWithEmail.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _emailAllPlayers(context, playersWithEmail, stats);
                    },
                    icon: const Icon(Icons.send),
                    label: Text('Email All (${playersWithEmail.length})'),
                  ),
                ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    for (final player in playersWithEmail)
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(player.displayName),
                        subtitle: Text(player.email!),
                        trailing: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _emailPlayer(context, player, stats);
                          },
                        ),
                      ),
                    for (final player in playersWithoutEmail)
                      ListTile(
                        leading: Icon(
                          Icons.email_outlined,
                          color: Theme.of(ctx).colorScheme.onSurface.withAlpha(77),
                        ),
                        title: Text(player.displayName),
                        subtitle: Text(
                          'No email on file',
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.onSurface.withAlpha(102),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _emailPlayer(
    BuildContext context,
    Player player,
    List<PlayerSeasonStatsModel> allStats,
  ) async {
    final playerStats = allStats.where((s) => s.playerId == player.id).toList();
    if (playerStats.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No stats found for ${player.displayName}')),
        );
      }
      return;
    }

    final body = StatsEmailFormatter.formatPlayerStats(
      playerStats.first,
      player.firstName,
      'volleyball',
    );

    final uri = Uri(
      scheme: 'mailto',
      path: player.email,
      queryParameters: {
        'subject': 'StatLine - ${player.displayName} Season Stats',
        'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email client')),
      );
    }
  }

  Future<void> _emailAllPlayers(
    BuildContext context,
    List<Player> players,
    List<PlayerSeasonStatsModel> allStats,
  ) async {
    var sent = 0;
    var skipped = 0;
    for (final player in players) {
      final playerStats =
          allStats.where((s) => s.playerId == player.id).toList();
      if (playerStats.isEmpty) {
        skipped++;
        continue;
      }

      final body = StatsEmailFormatter.formatPlayerStats(
        playerStats.first,
        player.firstName,
        'volleyball',
      );

      final uri = Uri(
        scheme: 'mailto',
        path: player.email,
        queryParameters: {
          'subject': 'StatLine - ${player.displayName} Season Stats',
          'body': body,
        },
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        sent++;
        // Brief delay between launches so email client can handle them
        if (sent < players.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } else {
        skipped++;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(skipped == 0
              ? 'Opened $sent email(s)'
              : 'Opened $sent email(s), $skipped skipped'),
        ),
      );
    }
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
