import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../widgets/sport_icon.dart';
import '../../../domain/models/team.dart';
import 'edit_team_screen.dart';
import 'team_detail_screen.dart';
import 'season_screen.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider);
    final selectedTeam = ref.watch(selectedTeamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final isSelected = selectedTeam?.id == team.id;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: SportIcon(sport: team.sport, size: 32),
                  title: Text(
                    team.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${team.level} • ${team.gender}${team.ageGroup != null ? ' • ${team.ageGroup}' : ''}',
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary)
                      : const Icon(Icons.chevron_right),
                  selected: isSelected,
                  onTap: () {
                    ref.read(selectedTeamProvider.notifier).state = team;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamDetailScreen(team: team),
                      ),
                    );
                  },
                  onLongPress: () =>
                      _showTeamOptions(context, ref, team),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTeamDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(102),
            ),
            const SizedBox(height: 24),
            Text(
              'Create your first team',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a team to start tracking stats',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(128),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamOptions(
      BuildContext context, WidgetRef ref, Team team) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Team'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTeamScreen(team: team),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Manage Seasons'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeasonScreen(team: team),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Set as Active Team'),
              onTap: () {
                ref.read(selectedTeamProvider.notifier).state = team;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Team'),
              onTap: () {
                Navigator.pop(context);
                _showCopyTeamDialog(context, ref, team);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete,
                  color: Theme.of(context).colorScheme.error),
              title: Text(
                'Delete Team',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref, team);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team?'),
        content: Text(
            'Are you sure you want to delete "${team.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(teamsProvider.notifier).deleteTeam(team.id);
              if (ref.read(selectedTeamProvider)?.id == team.id) {
                ref.read(selectedTeamProvider.notifier).state = null;
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCopyTeamDialog(
      BuildContext context, WidgetRef ref, Team source) {
    final nameController = TextEditingController(text: '${source.name} (Copy)');
    bool copyRoster = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Copy Team'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${source.sport[0].toUpperCase()}${source.sport.substring(1)} • ${source.level} • ${source.gender}${source.ageGroup != null ? ' • ${source.ageGroup}' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                          ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Copy roster'),
                      subtitle: const Text('Include all players'),
                      value: copyRoster,
                      onChanged: (v) =>
                          setDialogState(() => copyRoster = v),
                    ),
                  ],
                ),
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
                    final newTeamId = 'team_${now.millisecondsSinceEpoch}';
                    final newTeam = source.copyWith(
                      id: newTeamId,
                      name: nameController.text,
                      createdAt: now,
                      updatedAt: now,
                    );
                    ref.read(teamsProvider.notifier).addTeam(newTeam);

                    if (copyRoster) {
                      final roster = ref.read(rosterProvider);
                      roster.whenData((entries) {
                        final sourceEntries = entries
                            .where((e) => e.teamId == source.id)
                            .toList();
                        for (var i = 0; i < sourceEntries.length; i++) {
                          final e = sourceEntries[i];
                          ref.read(rosterProvider.notifier).addEntry(
                                e.copyWith(
                                  id: 'roster_${now.millisecondsSinceEpoch}_$i',
                                  teamId: newTeamId,
                                  joinedDate: now,
                                ),
                              );
                        }
                      });
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('Copy'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTeamDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String sport = 'volleyball';
    String level = 'Club';
    String gender = 'Female';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Team'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        hintText: 'e.g., Thunder VBC 16-1',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: sport,
                      decoration:
                          const InputDecoration(labelText: 'Sport'),
                      items: const [
                        DropdownMenuItem(
                            value: 'volleyball',
                            child: Text('Volleyball')),
                        DropdownMenuItem(
                            value: 'basketball',
                            child: Text('Basketball')),
                        DropdownMenuItem(
                            value: 'baseball',
                            child: Text('Baseball')),
                        DropdownMenuItem(
                            value: 'slowpitch',
                            child: Text('Slowpitch Softball')),
                        DropdownMenuItem(
                            value: 'football',
                            child: Text('Football')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => sport = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: level,
                      decoration:
                          const InputDecoration(labelText: 'Level'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Youth', child: Text('Youth')),
                        DropdownMenuItem(
                            value: 'Club', child: Text('Club / Travel')),
                        DropdownMenuItem(
                            value: 'High School',
                            child: Text('High School')),
                        DropdownMenuItem(
                            value: 'College',
                            child: Text('College')),
                        DropdownMenuItem(
                            value: 'Recreation',
                            child: Text('Recreation')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => level = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration:
                          const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                        DropdownMenuItem(
                            value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Coed', child: Text('Coed')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => gender = v!),
                    ),
                  ],
                ),
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
                    final team = Team(
                      id: 'team_${now.millisecondsSinceEpoch}',
                      name: nameController.text,
                      sport: sport,
                      level: level,
                      gender: gender,
                      createdAt: now,
                      updatedAt: now,
                    );
                    ref.read(teamsProvider.notifier).addTeam(team);
                    ref.read(selectedTeamProvider.notifier).state = team;
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
