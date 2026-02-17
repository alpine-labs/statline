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
    ActionDef(label: 'Kill', category: 'attack', type: 'attack', result: 'kill', icon: Icons.flash_on, tone: ActionTone.positive, scoreChange: 1),
    ActionDef(label: 'Error', category: 'attack', type: 'attack', result: 'error', icon: Icons.error_outline, tone: ActionTone.negative, scoreChange: -1),
    ActionDef(label: 'Ace', category: 'serve', type: 'serve', result: 'ace', icon: Icons.star, tone: ActionTone.positive, scoreChange: 1),
    ActionDef(label: 'Srv Err', category: 'serve', type: 'serve', result: 'error', icon: Icons.close, tone: ActionTone.negative, scoreChange: -1),
    ActionDef(label: 'Block', category: 'block', type: 'block', result: 'solo', icon: Icons.front_hand, tone: ActionTone.positive, scoreChange: 1),
    ActionDef(label: 'Dig', category: 'defense', type: 'dig', result: 'success', icon: Icons.sports, tone: ActionTone.neutral),
    ActionDef(label: 'Assist', category: 'setting', type: 'assist', result: 'success', icon: Icons.handshake, tone: ActionTone.positive),
    ActionDef(label: 'Opp Err', category: 'opponent', type: 'error', result: 'error', icon: Icons.celebration, tone: ActionTone.positive, scoreChange: 1),
  ];

  static const _detailedExtraActions = [
    ActionDef(label: 'Atk Blk', category: 'attack', type: 'attack', result: 'blocked', icon: Icons.block, tone: ActionTone.negative, scoreChange: -1),
    ActionDef(label: '0 Atk', category: 'attack', type: 'attack', result: 'zero', icon: Icons.exposure_zero, tone: ActionTone.neutral),
    ActionDef(label: 'Blk Ast', category: 'block', type: 'block', result: 'assist', icon: Icons.people, tone: ActionTone.positive, scoreChange: 1),
    ActionDef(label: 'Blk Err', category: 'block', type: 'block', result: 'error', icon: Icons.warning, tone: ActionTone.negative, scoreChange: -1),
    ActionDef(label: 'Pass 3', category: 'reception', type: 'pass', result: '3', icon: Icons.looks_3, tone: ActionTone.positive),
    ActionDef(label: 'Pass 2', category: 'reception', type: 'pass', result: '2', icon: Icons.looks_two, tone: ActionTone.neutral),
    ActionDef(label: 'Pass 1', category: 'reception', type: 'pass', result: '1', icon: Icons.looks_one, tone: ActionTone.neutral),
    ActionDef(label: 'Pass 0', category: 'reception', type: 'pass', result: '0', icon: Icons.exposure_zero, tone: ActionTone.negative),
    ActionDef(label: 'Dig Err', category: 'defense', type: 'dig', result: 'error', icon: Icons.do_not_disturb, tone: ActionTone.negative),
    ActionDef(label: 'Srv In', category: 'serve', type: 'serve', result: 'in_play', icon: Icons.check, tone: ActionTone.neutral),
    ActionDef(label: 'Set Err', category: 'setting', type: 'set', result: 'error', icon: Icons.cancel, tone: ActionTone.negative),
    ActionDef(label: 'Rec Err', category: 'reception', type: 'reception', result: 'error', icon: Icons.error, tone: ActionTone.negative, scoreChange: -1),
  ];

  @override
  Widget build(BuildContext context) {
    final actions = entryMode == 'detailed'
        ? [..._quickActions, ..._detailedExtraActions]
        : _quickActions;

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
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _ActionButton(
            action: action,
            onTap: () => onAction(
                action.category, action.type, action.result, action.scoreChange),
          );
        },
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
