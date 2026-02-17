import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../../domain/models/team.dart';
import '../../../domain/models/roster_entry.dart';
import '../../../core/theme/colors.dart';
import 'player_form_screen.dart';

class RosterScreen extends ConsumerWidget {
  final Team team;

  const RosterScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${team.name} Roster'),
      ),
      body: rosterAsync.when(
        data: (roster) {
          // Filter for this team
          final teamRoster =
              roster.where((r) => r.teamId == team.id).toList();

          if (teamRoster.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withAlpha(102),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No players on roster',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add players',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(128),
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort: starters first, then by jersey number
          teamRoster.sort((a, b) {
            if (a.role == 'starter' && b.role != 'starter') return -1;
            if (a.role != 'starter' && b.role == 'starter') return 1;
            return int.tryParse(a.jerseyNumber)
                    ?.compareTo(int.tryParse(b.jerseyNumber) ?? 0) ??
                0;
          });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: teamRoster.length,
            itemBuilder: (context, index) {
              final entry = teamRoster[index];
              return _buildRosterTile(context, ref, entry);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerFormScreen(team: team),
            ),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildRosterTile(
      BuildContext context, WidgetRef ref, RosterEntry entry) {
    final player = entry.player;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Player?'),
            content: Text(
                'Remove ${player?.displayName ?? 'this player'} from the roster?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(rosterProvider.notifier).removeEntry(entry.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withAlpha(51),
            child: Text(
              '#${entry.jerseyNumber}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          title: Text(
            player?.displayName ?? 'Unknown Player',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Row(
            children: [
              Text(player?.positions.join(', ') ?? ''),
              if (entry.role == 'starter') ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Starter',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (entry.isLibero) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: StatLineColors.secondaryAccent.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Libero',
                    style: TextStyle(
                      fontSize: 10,
                      color: StatLineColors.secondaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerFormScreen(
                  team: team,
                  player: player,
                  rosterEntry: entry,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
