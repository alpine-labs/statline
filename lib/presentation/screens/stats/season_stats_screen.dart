import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/stats_providers.dart';
import '../../providers/team_providers.dart';
import '../../widgets/export_button.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/player_stats.dart';
import '../../../domain/sports/sport_plugin.dart';
import '../../../domain/stats/stat_calculator.dart';
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
  String? _sortColumn;
  bool _sortAscending = false;
  final Set<String> _selectedPlayerIds = {};

  String _effectiveSortColumn(SportPlugin? plugin) {
    if (_sortColumn != null) return _sortColumn!;
    if (plugin != null && plugin.seasonStatsColumns.isNotEmpty) {
      return plugin.seasonStatsColumns.first.key;
    }
    return 'kills'; // fallback
  }

  SportPlugin? _pluginForSport(String? sport) {
    if (sport == null) return null;
    try {
      return StatCalculator.getSportPlugin(sport);
    } catch (_) {
      return null;
    }
  }

  List<String> _filtersForPlugin(SportPlugin? plugin) {
    if (plugin == null) return const ['All'];
    return ['All', ...plugin.statFilterCategories.keys];
  }

  List<StatsColumnDef> _columnsForFilter(String filter, SportPlugin? plugin) {
    const playerCol =
        StatsColumnDef(key: 'player', label: 'Player', isNumeric: false);
    const gpCol = StatsColumnDef(key: 'gp', label: 'GP');

    if (plugin == null) return [playerCol, gpCol];

    if (filter != 'All') {
      final keys = plugin.statFilterCategories[filter];
      if (keys != null) {
        return [
          playerCol,
          gpCol,
          ...keys.map((k) {
            final col = plugin.seasonStatsColumns
                .where((c) => c.key == k);
            final label = col.isNotEmpty ? col.first.shortLabel : k;
            return StatsColumnDef(key: k, label: label);
          }),
        ];
      }
    }

    // 'All' filter: use all season stat columns
    return [
      playerCol,
      gpCol,
      ...plugin.seasonStatsColumns
          .map((c) => StatsColumnDef(key: c.key, label: c.shortLabel)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(seasonStatsProvider);
    final playersAsync = ref.watch(playersProvider);
    final selectedTeam = ref.watch(selectedTeamProvider);
    final sport = selectedTeam?.sport;
    final plugin = _pluginForSport(sport);
    final filters = _filtersForPlugin(plugin);

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
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
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
                final columns = _columnsForFilter(_activeFilter, plugin);
                final rows = _buildRows(stats, players, columns);

                return StatsTable(
                  columns: columns,
                  rows: rows,
                  sortColumnKey: _effectiveSortColumn(plugin),
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


  List<StatsRowData> _buildRows(
    List<PlayerSeasonStatsModel> stats,
    List<dynamic> players,
    List<StatsColumnDef> columns,
  ) {
    String getPlayerName(String playerId) {
      final p = players.where((p) => p.id == playerId);
      return p.isNotEmpty ? p.first.shortName : playerId;
    }

    final sortKey = _effectiveSortColumn(
        _pluginForSport(ref.read(selectedTeamProvider)?.sport));

    final rows = stats.map((s) {
      final totals = s.statsTotals;
      final metrics = s.computedMetrics;

      final values = <String, dynamic>{
        'player': getPlayerName(s.playerId),
        'playerId': s.playerId,
        'gp': s.gamesPlayed,
      };

      // Populate all column keys from totals and metrics
      for (final col in columns) {
        if (values.containsKey(col.key)) continue;
        if (metrics.containsKey(col.key)) {
          values[col.key] = metrics[col.key];
        } else if (totals.containsKey(col.key)) {
          values[col.key] = totals[col.key] ?? 0;
        } else {
          values[col.key] = 0;
        }
      }

      return StatsRowData(playerId: s.playerId, values: values);
    }).toList();

    // Sort
    rows.sort((a, b) {
      final aVal = a.values[sortKey];
      final bVal = b.values[sortKey];
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

    final sport = ref.read(selectedTeamProvider)?.sport ?? 'volleyball';

    final body = StatsEmailFormatter.formatPlayerStats(
      playerStats.first,
      player.firstName,
      sport,
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
    final sport = ref.read(selectedTeamProvider)?.sport ?? 'volleyball';
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
        sport,
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

      final sport = ref.read(selectedTeamProvider)?.sport ?? 'volleyball';
      final csv = CsvExporter.exportSeasonStats(
        stats,
        sport,
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
