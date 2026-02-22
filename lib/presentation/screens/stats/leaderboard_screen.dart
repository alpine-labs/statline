import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stats_providers.dart';
import '../../providers/team_providers.dart';
import '../../../domain/models/player_stats.dart';
import '../../../domain/sports/sport_plugin.dart';
import '../../../domain/stats/stat_calculator.dart';

/// Top players ranked by stat category.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String? _selectedStatKey;

  List<StatColumn> _columnsForSport(String sport) {
    try {
      final plugin = StatCalculator.getSportPlugin(sport);
      return plugin.seasonStatsColumns;
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(seasonStatsProvider);
    final playersAsync = ref.watch(playersProvider);
    final selectedTeam = ref.watch(selectedTeamProvider);
    final sport = selectedTeam?.sport ?? 'volleyball';
    final columns = _columnsForSport(sport);

    // Default to first column if none selected or selection doesn't match
    if (_selectedStatKey == null ||
        !columns.any((c) => c.key == _selectedStatKey)) {
      _selectedStatKey = columns.isNotEmpty ? columns.first.key : null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          // Filter chips from plugin columns
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: columns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final col = columns[index];
                return FilterChip(
                  label: Text(col.shortLabel),
                  selected: col.key == _selectedStatKey,
                  onSelected: (_) =>
                      setState(() => _selectedStatKey = col.key),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Ranked list
          Expanded(
            child: statsAsync.when(
              data: (stats) {
                if (stats.isEmpty || _selectedStatKey == null) {
                  return const Center(child: Text('No stats available yet'));
                }

                final col = columns.firstWhere(
                  (c) => c.key == _selectedStatKey,
                  orElse: () => columns.first,
                );
                final players = playersAsync.valueOrNull ?? [];
                final ranked = _buildRankedList(stats, players, col);

                return ListView.builder(
                  itemCount: ranked.length,
                  itemBuilder: (context, index) {
                    final entry = ranked[index];
                    final rank = index + 1;
                    return _LeaderboardTile(
                      rank: rank,
                      playerName: entry.playerName,
                      jerseyNumber: entry.jerseyNumber,
                      value: entry.formattedValue,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  List<_RankedEntry> _buildRankedList(
    List<PlayerSeasonStatsModel> stats,
    List<dynamic> players,
    StatColumn column,
  ) {
    String getPlayerName(String playerId) {
      final p = players.where((p) => p.id == playerId);
      return p.isNotEmpty ? p.first.displayName : playerId;
    }

    String getJerseyNumber(String playerId) {
      final p = players.where((p) => p.id == playerId);
      return p.isNotEmpty ? p.first.jerseyNumber : '';
    }

    final entries = stats.map((s) {
      final totals = s.statsTotals;
      final metrics = s.computedMetrics;

      // Look up value from totals first, then computed metrics
      final raw = totals[column.key] ?? metrics[column.key] ?? 0;
      final double rawValue = (raw is num) ? raw.toDouble() : 0.0;
      final formatted = _formatValue(rawValue, column.format, totals);

      return _RankedEntry(
        playerName: getPlayerName(s.playerId),
        jerseyNumber: getJerseyNumber(s.playerId),
        rawValue: rawValue,
        formattedValue: formatted,
      );
    }).toList();

    entries.sort((a, b) => b.rawValue.compareTo(a.rawValue));
    return entries;
  }

  static String _formatValue(
      double value, String? format, Map<String, dynamic> totals) {
    switch (format) {
      case 'decimal3':
        // Hitting percentage style: .350 format
        final millis = (value * 1000).round();
        final neg = millis < 0;
        return '${neg ? "-" : ""}.${millis.abs().toString().padLeft(3, '0')}';
      case 'decimal2':
        return value.toStringAsFixed(2);
      case 'percentage':
        return '${(value * 100).toStringAsFixed(1)}%';
      case 'int':
        return value.toStringAsFixed(0);
      default:
        return value.toStringAsFixed(0);
    }
  }
}

class _RankedEntry {
  final String playerName;
  final String jerseyNumber;
  final double rawValue;
  final String formattedValue;

  const _RankedEntry({
    required this.playerName,
    required this.jerseyNumber,
    required this.rawValue,
    required this.formattedValue,
  });
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final String playerName;
  final String jerseyNumber;
  final String value;

  const _LeaderboardTile({
    required this.rank,
    required this.playerName,
    required this.jerseyNumber,
    required this.value,
  });

  String get _rankDisplay {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;

    return ListTile(
      leading: SizedBox(
        width: 36,
        child: Center(
          child: Text(
            _rankDisplay,
            style: isTopThree
                ? const TextStyle(fontSize: 22)
                : Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(153),
                    ),
          ),
        ),
      ),
      title: Text(
        playerName,
        style: isTopThree
            ? Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold)
            : null,
      ),
      subtitle: jerseyNumber.isNotEmpty ? Text('#$jerseyNumber') : null,
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
