import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../../domain/models/team.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/roster_entry.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  final Team team;
  final Player? player;
  final RosterEntry? rosterEntry;

  const PlayerFormScreen({
    super.key,
    required this.team,
    this.player,
    this.rosterEntry,
  });

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _jerseyController;
  late final TextEditingController _emailController;
  final Set<String> _selectedPositions = {};

  bool get isEditing => widget.player != null;

  static const _volleyballPositions = [
    'OH',
    'MB',
    'S',
    'OPP',
    'L',
    'DS',
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.player?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.player?.lastName ?? '');
    _jerseyController =
        TextEditingController(text: widget.player?.jerseyNumber ?? '');
    _emailController =
        TextEditingController(text: widget.player?.email ?? '');
    if (widget.player != null) {
      _selectedPositions.addAll(widget.player!.positions);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jerseyController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Player' : 'Add Player'),
        actions: [
          TextButton(
            onPressed: _savePlayer,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo placeholder
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withAlpha(51),
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // First name
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                hintText: 'Enter first name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last name
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                hintText: 'Enter last name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Jersey number
            TextFormField(
              controller: _jerseyController,
              decoration: const InputDecoration(
                labelText: 'Jersey Number',
                hintText: 'Enter jersey number',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jersey number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email (optional)
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                hintText: 'player@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            // Positions
            Text(
              'Positions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _volleyballPositions.map((pos) {
                final isSelected = _selectedPositions.contains(pos);
                return FilterChip(
                  label: Text(pos),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPositions.add(pos);
                      } else {
                        _selectedPositions.remove(pos);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'OH: Outside Hitter  MB: Middle Blocker  S: Setter\n'
              'OPP: Opposite  L: Libero  DS: Defensive Specialist',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(102),
                  ),
            ),
            const SizedBox(height: 32),

            // Save/Cancel buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _savePlayer,
                    child: Text(isEditing ? 'Update' : 'Add Player'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _savePlayer() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    if (isEditing) {
      final updatedPlayer = widget.player!.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        jerseyNumber: _jerseyController.text,
        positions: _selectedPositions.toList(),
        email: () => _emailController.text.isEmpty ? null : _emailController.text,
        updatedAt: now,
      );
      ref.read(playersProvider.notifier).updatePlayer(updatedPlayer);

      if (widget.rosterEntry != null) {
        final updatedEntry = widget.rosterEntry!.copyWith(
          jerseyNumber: _jerseyController.text,
          isLibero: _selectedPositions.contains('L'),
          player: () => updatedPlayer,
        );
        ref.read(rosterProvider.notifier).updateEntry(updatedEntry);
      }
    } else {
      final newPlayer = Player(
        id: 'player_${now.millisecondsSinceEpoch}',
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        jerseyNumber: _jerseyController.text,
        positions: _selectedPositions.toList(),
        email: _emailController.text.isEmpty ? null : _emailController.text,
        createdAt: now,
        updatedAt: now,
      );
      ref.read(playersProvider.notifier).addPlayer(newPlayer);

      final newEntry = RosterEntry(
        id: 'roster_${now.millisecondsSinceEpoch}',
        teamId: widget.team.id,
        playerId: newPlayer.id,
        seasonId: 's1',
        jerseyNumber: _jerseyController.text,
        role: 'reserve',
        isLibero: _selectedPositions.contains('L'),
        joinedDate: now,
        player: newPlayer,
      );
      ref.read(rosterProvider.notifier).addEntry(newEntry);
    }

    Navigator.pop(context);
  }
}
