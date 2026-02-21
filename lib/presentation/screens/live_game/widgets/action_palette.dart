import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// Action button data.
class ActionDef {
  final String label;
  final String category;
  final String type;
  final String result;
  final IconData icon;
  final ActionTone tone;
  final int scoreChange; // +1 = us point, -1 = them point, 0 = neutral

  const ActionDef({
    required this.label,
    required this.category,
    required this.type,
    required this.result,
    required this.icon,
    this.tone = ActionTone.neutral,
    this.scoreChange = 0,
  });
}

enum ActionTone { positive, negative, neutral }

/// Action palette shown when a player is selected.
class ActionPalette extends StatelessWidget {
  final String entryMode;
  final void Function(String category, String type, String result, int scoreChange) onAction;

  const ActionPalette({
    super.key,
    required this.entryMode,
    required this.onAction,
  });

  static const _quickActions = [
    ActionDef(label: 'Kill', category: 'attack', type: 'kill', result: 'kill', icon: Icons.flash_on, tone: ActionTone.positive, scoreChange: 1),
    ActionDef(label: 'Error', category: 'attack', type: 'attack_error', result: 'error', icon: Icons.error_outline, tone: ActionTone.negative, scoreChange: -1),
    ActionDef(label: 'Dig', category: 'defense', type: 'dig', result: 'success', icon: Icons.sports, tone: ActionTone.neutral),
    ActionDef(label: 'Assist', category: 'setting', type: 'set_assist', result: 'success', icon: Icons.handshake, tone: ActionTone.positive),
    ActionDef(label: 'Block', category: 'block', type: 'block_solo', result: 'solo', icon: Icons.front_hand, tone: ActionTone.positive, scoreChange: 1),
    ActionDef(label: 'Ace', category: 'serve', type: 'ace', result: 'ace', icon: Icons.star, tone: ActionTone.positive, scoreChange: 1),
    ActionDef(label: 'Srv Err', category: 'serve', type: 'serve_error', result: 'error', icon: Icons.close, tone: ActionTone.negative, scoreChange: -1),
    ActionDef(label: 'Opp Err', category: 'opponent', type: 'opp_error', result: 'error', icon: Icons.celebration, tone: ActionTone.positive, scoreChange: 1),
  ];

  static const _detailedExtraActions = [
    ActionDef(label: 'Atk Blk', category: 'attack', type: 'blocked', result: 'blocked', icon: Icons.block, tone: ActionTone.negative, scoreChange: -1),
    ActionDef(label: '0 Atk', category: 'attack', type: 'zero_attack', result: 'zero', icon: Icons.exposure_zero, tone: ActionTone.neutral),
    ActionDef(label: 'Blk Ast', category: 'block', type: 'block_assist', result: 'assist', icon: Icons.people, tone: ActionTone.positive, scoreChange: 1),
    ActionDef(label: 'Blk Err', category: 'block', type: 'block_error', result: 'error', icon: Icons.warning, tone: ActionTone.negative, scoreChange: -1),
    ActionDef(label: 'Pass 3', category: 'reception', type: 'pass_3', result: '3', icon: Icons.looks_3, tone: ActionTone.positive),
    ActionDef(label: 'Pass 2', category: 'reception', type: 'pass_2', result: '2', icon: Icons.looks_two, tone: ActionTone.neutral),
    ActionDef(label: 'Pass 1', category: 'reception', type: 'pass_1', result: '1', icon: Icons.looks_one, tone: ActionTone.neutral),
    ActionDef(label: 'Shank', category: 'reception', type: 'pass_0', result: '0', icon: Icons.exposure_zero, tone: ActionTone.negative),
    ActionDef(label: 'Overpass', category: 'reception', type: 'overpass', result: '0', icon: Icons.arrow_upward, tone: ActionTone.negative),
    ActionDef(label: 'Dig Err', category: 'defense', type: 'dig_error', result: 'error', icon: Icons.do_not_disturb, tone: ActionTone.negative),
    ActionDef(label: 'Srv In', category: 'serve', type: 'serve_in_play', result: 'in_play', icon: Icons.check, tone: ActionTone.neutral),
    ActionDef(label: 'Set Err', category: 'setting', type: 'set_error', result: 'error', icon: Icons.cancel, tone: ActionTone.negative),
    ActionDef(label: 'Rec Err', category: 'reception', type: 'pass_error', result: 'error', icon: Icons.error, tone: ActionTone.negative, scoreChange: -1),
  ];

  // Category grouping for detailed mode, keyed by display label.
  static const _categoryOrder = ['ATTACK', 'SERVE', 'BLOCK', 'DIG/PASS', 'SET', 'OPP'];

  static const _actionToCategory = <String, String>{
    'Kill': 'ATTACK', 'Error': 'ATTACK', 'Atk Blk': 'ATTACK', '0 Atk': 'ATTACK',
    'Ace': 'SERVE', 'Srv Err': 'SERVE', 'Srv In': 'SERVE',
    'Block': 'BLOCK', 'Blk Ast': 'BLOCK', 'Blk Err': 'BLOCK',
    'Dig': 'DIG/PASS', 'Dig Err': 'DIG/PASS', 'Pass 3': 'DIG/PASS',
    'Pass 2': 'DIG/PASS', 'Pass 1': 'DIG/PASS', 'Shank': 'DIG/PASS',
    'Overpass': 'DIG/PASS', 'Rec Err': 'DIG/PASS',
    'Assist': 'SET', 'Set Err': 'SET',
    'Opp Err': 'OPP',
  };

  @override
  Widget build(BuildContext context) {
    if (entryMode != 'detailed') {
      return _buildQuickGrid();
    }
    return _buildDetailedGrouped();
  }

  Widget _buildQuickGrid() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.6,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: _quickActions.length,
        itemBuilder: (context, index) {
          final action = _quickActions[index];
          return _ActionButton(
            action: action,
            onTap: () => onAction(
                action.category, action.type, action.result, action.scoreChange),
          );
        },
      ),
    );
  }

  Widget _buildDetailedGrouped() {
    final allActions = [..._quickActions, ..._detailedExtraActions];
    final grouped = <String, List<ActionDef>>{};
    for (final cat in _categoryOrder) {
      grouped[cat] = [];
    }
    for (final action in allActions) {
      final cat = _actionToCategory[action.label] ?? 'OPP';
      grouped[cat]!.add(action);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final cat in _categoryOrder)
              if (grouped[cat]!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 2, top: 4, bottom: 2),
                  child: Text(
                    cat,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: grouped[cat]!.map((action) {
                    return SizedBox(
                      width: 80,
                      height: 50,
                      child: _ActionButton(
                        action: action,
                        onTap: () => onAction(action.category, action.type,
                            action.result, action.scoreChange),
                      ),
                    );
                  }).toList(),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ActionDef action;
  final VoidCallback onTap;

  const _ActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;

    switch (action.tone) {
      case ActionTone.positive:
        bgColor = StatLineColors.pointScored.withAlpha(38);
        fgColor = StatLineColors.pointScored;
        break;
      case ActionTone.negative:
        bgColor = StatLineColors.pointLost.withAlpha(38);
        fgColor = StatLineColors.pointLost;
        break;
      case ActionTone.neutral:
        bgColor = const Color(0xFF2A2A2A);
        fgColor = Colors.white70;
        break;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 18, color: fgColor),
            const SizedBox(height: 2),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
