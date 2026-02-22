import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../../domain/models/team.dart';

class EditTeamScreen extends ConsumerStatefulWidget {
  final Team team;

  const EditTeamScreen({super.key, required this.team});

  @override
  ConsumerState<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends ConsumerState<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageGroupController;
  late String _sport;
  late String _level;
  late String _gender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.name);
    _ageGroupController =
        TextEditingController(text: widget.team.ageGroup ?? '');
    _sport = widget.team.sport;
    _level = widget.team.level;
    _gender = widget.team.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Team'),
        actions: [
          TextButton(
            onPressed: _saveTeam,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'e.g., Thunder VBC 16-1',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Team name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sport,
              decoration: const InputDecoration(labelText: 'Sport'),
              items: const [
                DropdownMenuItem(value: 'volleyball', child: Text('Volleyball')),
                DropdownMenuItem(value: 'basketball', child: Text('Basketball')),
                DropdownMenuItem(value: 'baseball', child: Text('Baseball')),
                DropdownMenuItem(
                    value: 'slowpitch', child: Text('Slowpitch Softball')),
                DropdownMenuItem(value: 'football', child: Text('Football')),
              ],
              onChanged: (v) => setState(() => _sport = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _level,
              decoration: const InputDecoration(labelText: 'Level'),
              items: const [
                DropdownMenuItem(value: 'Youth', child: Text('Youth')),
                DropdownMenuItem(value: 'Club', child: Text('Club / Travel')),
                DropdownMenuItem(
                    value: 'High School', child: Text('High School')),
                DropdownMenuItem(value: 'College', child: Text('College')),
                DropdownMenuItem(
                    value: 'Recreation', child: Text('Recreation')),
              ],
              onChanged: (v) => setState(() => _level = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Coed', child: Text('Coed')),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageGroupController,
              decoration: const InputDecoration(
                labelText: 'Age Group (optional)',
                hintText: 'e.g., 16U',
              ),
            ),
            const SizedBox(height: 32),
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
                    onPressed: _saveTeam,
                    child: const Text('Update Team'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveTeam() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.team.copyWith(
      name: _nameController.text,
      sport: _sport,
      level: _level,
      gender: _gender,
      ageGroup: () =>
          _ageGroupController.text.isEmpty ? null : _ageGroupController.text,
      updatedAt: DateTime.now(),
    );

    ref.read(teamsProvider.notifier).updateTeam(updated);

    // Keep selectedTeamProvider in sync if this was the active team.
    final selected = ref.read(selectedTeamProvider);
    if (selected?.id == updated.id) {
      ref.read(selectedTeamProvider.notifier).state = updated;
    }

    Navigator.pop(context);
  }
}
