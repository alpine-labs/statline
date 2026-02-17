import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../../domain/models/team.dart';
import '../../../domain/models/season.dart';

class SeasonScreen extends ConsumerWidget {
  final Team team;

  const SeasonScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(seasonsProvider);
    final activeSeason = ref.watch(activeSeasonProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${team.name} Seasons'),
      ),
      body: seasonsAsync.when(
        data: (seasons) {
          final teamSeasons =
              seasons.where((s) => s.teamId == team.id).toList();

          if (teamSeasons.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withAlpha(102),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No seasons yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          _showCreateSeasonDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Season'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort: active first, then by start date descending
          teamSeasons.sort((a, b) {
            if (a.isActive && !b.isActive) return -1;
            if (!a.isActive && b.isActive) return 1;
            return b.startDate.compareTo(a.startDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: teamSeasons.length,
            itemBuilder: (context, index) {
              final season = teamSeasons[index];
              final isActive = activeSeason?.id == season.id;

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    season.isActive
                        ? Icons.calendar_today
                        : Icons.calendar_month,
                    color: season.isActive
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(season.name),
                  subtitle: Text(_formatDateRange(season)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (season.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.check_circle,
                            color:
                                Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    ref.read(activeSeasonProvider.notifier).state = season;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('${season.name} set as active season'),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSeasonDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateRange(Season season) {
    final start =
        '${season.startDate.month}/${season.startDate.day}/${season.startDate.year}';
    if (season.endDate != null) {
      final end =
          '${season.endDate!.month}/${season.endDate!.day}/${season.endDate!.year}';
      return '$start - $end';
    }
    return '$start - Present';
  }

  void _showCreateSeasonDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    DateTime startDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Season'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Season Name',
                      hintText: 'e.g., 2024-25 Season',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start Date'),
                    subtitle: Text(
                      '${startDate.month}/${startDate.day}/${startDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) return;
                    final now = DateTime.now();
                    final season = Season(
                      id: 'season_${now.millisecondsSinceEpoch}',
                      teamId: team.id,
                      name: nameController.text,
                      startDate: startDate,
                      isActive: true,
                      createdAt: now,
                      updatedAt: now,
                    );
                    ref.read(seasonsProvider.notifier).addSeason(season);
                    ref.read(activeSeasonProvider.notifier).state = season;
                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
