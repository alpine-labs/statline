import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/feature_flags/feature_flags.dart';

// ── Settings providers ───────────────────────────────────────────────────────

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final defaultEntryModeProvider =
    StateProvider<String>((ref) => 'quick');
final defaultSportProvider =
    StateProvider<String>((ref) => 'volleyball');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final entryMode = ref.watch(defaultEntryModeProvider);
    final defaultSport = ref.watch(defaultSportProvider);
    final featureFlags = FeatureFlags();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selected) {
                ref.read(themeModeProvider.notifier).state =
                    selected.first;
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const Divider(),

          // ── Defaults ────────────────────────────────────────────────────
          _SectionHeader(title: 'Defaults'),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Default Entry Mode'),
            subtitle: Text(
                entryMode == 'quick' ? 'Quick Mode' : 'Detailed Mode'),
            trailing: Switch(
              value: entryMode == 'detailed',
              onChanged: (v) {
                ref.read(defaultEntryModeProvider.notifier).state =
                    v ? 'detailed' : 'quick';
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sports),
            title: const Text('Default Sport'),
            subtitle: Text(_sportLabel(defaultSport)),
            trailing: DropdownButton<String>(
              value: defaultSport,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                    value: 'volleyball', child: Text('Volleyball')),
                DropdownMenuItem(
                    value: 'basketball', child: Text('Basketball')),
                DropdownMenuItem(
                    value: 'baseball', child: Text('Baseball')),
                DropdownMenuItem(
                    value: 'slowpitch', child: Text('Slowpitch')),
                DropdownMenuItem(
                    value: 'football', child: Text('Football')),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(defaultSportProvider.notifier).state = v;
                }
              },
            ),
          ),
          const Divider(),

          // ── Data ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Data Management'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export Data'),
            subtitle: const Text('Export all data as CSV'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever,
                color: Theme.of(context).colorScheme.error),
            title: Text(
              'Clear All Data',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text('Delete all teams, games, and stats'),
            onTap: () => _showClearDataDialog(context),
          ),
          const Divider(),

          // ── Sync ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Sync'),
          ListTile(
            leading: const Icon(Icons.cloud_off),
            title: const Text('Sync Status'),
            subtitle: const Text('Offline mode — 0 pending changes'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Cloud sync will be available in a future update')),
              );
            },
          ),
          const Divider(),

          // ── Feature Flags ───────────────────────────────────────────────
          _SectionHeader(title: 'Feature Flags (Dev)'),
          ...Feature.values.map((feature) {
            final enabled = featureFlags.isEnabled(feature);
            final required = FeatureFlags.requiredTier(feature);
            return ListTile(
              dense: true,
              leading: Icon(
                enabled ? Icons.check_circle : Icons.lock,
                color: enabled ? Colors.green : Colors.grey,
                size: 20,
              ),
              title: Text(
                feature.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: Text(
                required.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                    ),
              ),
            );
          }),
          const Divider(),

          // ── About ───────────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('StatLine'),
            subtitle: Text('Version 1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Built by'),
            subtitle: Text('Alpine Labs'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  String _sportLabel(String sport) {
    return switch (sport) {
      'volleyball' => 'Volleyball',
      'basketball' => 'Basketball',
      'baseball' => 'Baseball',
      'slowpitch' => 'Slowpitch Softball',
      'football' => 'Football',
      _ => sport,
    };
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all teams, games, stats, and settings. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Data clearing will be available soon')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:
                  Theme.of(context).colorScheme.primary,
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}
