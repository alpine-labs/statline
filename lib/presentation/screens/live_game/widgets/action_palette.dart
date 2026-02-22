import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../domain/sports/sport_plugin.dart';
import '../../../../domain/stats/stat_calculator.dart';

/// Action button data derived from [EventType].
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

  /// Build an [ActionDef] from a plugin [EventType].
  factory ActionDef.fromEventType(EventType et) {
    final ActionTone tone;
    final int scoreChange;
    switch (et.defaultResult) {
      case 'point_us':
        tone = ActionTone.positive;
        scoreChange = 1;
        break;
      case 'point_them':
        tone = ActionTone.negative;
        scoreChange = -1;
        break;
      default:
        tone = ActionTone.neutral;
        scoreChange = 0;
    }
    return ActionDef(
      label: et.displayLabel,
      category: et.category,
      type: et.id,
      result: et.defaultResult,
      icon: et.icon ?? Icons.radio_button_unchecked,
      tone: tone,
      scoreChange: scoreChange,
    );
  }
}

enum ActionTone { positive, negative, neutral }

/// Action palette shown when a player is selected.
///
/// Reads event definitions from the [SportPlugin] for the given [sport],
/// so new sports get their own palette automatically.
class ActionPalette extends StatelessWidget {
  final String entryMode;
  final String sport;
  final void Function(String category, String type, String result, int scoreChange) onAction;

  const ActionPalette({
    super.key,
    required this.entryMode,
    required this.sport,
    required this.onAction,
  });

  SportPlugin get _plugin => StatCalculator.getSportPlugin(sport);

  List<ActionDef> get _quickActions {
    return _plugin.quickModeEvents
        .expand((c) => c.eventTypes)
        .map(ActionDef.fromEventType)
        .toList();
  }

  List<EventCategory> get _detailedCategories => _plugin.eventCategories;

  @override
  Widget build(BuildContext context) {
    if (entryMode != 'detailed') {
      return _buildQuickGrid();
    }
    return _buildDetailedGrouped();
  }

  Widget _buildQuickGrid() {
    final actions = _quickActions;
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

  Widget _buildDetailedGrouped() {
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
            for (final category in _detailedCategories)
              if (category.eventTypes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 2, top: 4, bottom: 2),
                  child: Text(
                    category.label.toUpperCase(),
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
                  children: category.eventTypes.map((et) {
                    final action = ActionDef.fromEventType(et);
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
