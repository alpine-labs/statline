import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stats_providers.dart';
import '../../providers/team_providers.dart';
import '../../../domain/models/player_stats.dart';

/// Top players ranked by stat category.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _selectedStat = 'Kills';

  static const _statCategories = [
    'Kills',
    'Hitting %',
    'Aces',
    'Digs',
    'Blocks',
    'Points',
    'Assists',
  ];

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(seasonStatsProvider);
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _statCategories[index];
                return FilterChip(
                  label: Text(cat),
                  selected: cat == _selectedStat,
                  onSelected: (_) => setState(() => _selectedStat = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Ranked list
          Expanded(
            child: statsAsync.when(
              data: (stats) {
                if (stats.isEmpty) {
                  return const Center(child: Text('No stats available yet'));
                }

                final players = playersAsync.valueOrNull ?? [];
                final ranked = _buildRankedList(stats, players);

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
      final bs = (totals['blockSolos'] ?? 0) as num;
      final ba = (totals['blockAssists'] ?? 0) as num;

      final double rawValue;
      final String formatted;

      switch (_selectedStat) {
        case 'Kills':
          rawValue = ((totals['kills'] ?? 0) as num).toDouble();
          formatted = rawValue.toStringAsFixed(0);
        case 'Hitting %':
          rawValue = ((metrics['hittingPercentage'] ?? 0.0) as num).toDouble();
          final ta = (totals['totalAttempts'] ?? 0) as num;
          if (ta == 0) {
            formatted = '---';
          } else {
            final millis = (rawValue * 1000).round();
            final neg = millis < 0;
            formatted =
                '${neg ? "-" : ""}.${millis.abs().toString().padLeft(3, '0')}';
          }
        case 'Aces':
          rawValue = ((totals['serviceAces'] ?? 0) as num).toDouble();
          formatted = rawValue.toStringAsFixed(0);
        case 'Digs':
          rawValue = ((totals['digs'] ?? 0) as num).toDouble();
          formatted = rawValue.toStringAsFixed(0);
        case 'Blocks':
          rawValue = (bs + ba).toDouble();
          formatted = rawValue.toStringAsFixed(0);
        case 'Points':
          rawValue = ((totals['points'] ?? 0) as num).toDouble();
          formatted = rawValue.toStringAsFixed(0);
        case 'Assists':
          rawValue = ((totals['assists'] ?? 0) as num).toDouble();
          formatted = rawValue.toStringAsFixed(0);
        default:
          rawValue = 0;
          formatted = '0';
      }

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
