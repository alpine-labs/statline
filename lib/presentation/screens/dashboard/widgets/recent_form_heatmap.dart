import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../providers/dashboard_insights_provider.dart';

/// Custom heatmap grid showing last 10 games with color-coded stats.
/// Built with Container/Row/Column — no fl_chart dependency.
class RecentFormHeatmap extends StatelessWidget {
  final RecentFormData data;
  final void Function(String gameId)? onTapGame;

  const RecentFormHeatmap({super.key, required this.data, this.onTapGame});

  static const _greenBg = Color(0xFFE8F5E9);
  static const _yellowBg = Color(0xFFFFF8E1);
  static const _redBg = Color(0xFFFFEBEE);

  @override
  Widget build(BuildContext context) {
    if (data.games.length < 3) {
      return _buildEmptyState(context);
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Compute thresholds for each stat column
    final hitThresholds = data.thresholdsFor((g) => g.hittingPct);
    final aceThresholds = data.thresholdsFor((g) => g.aces.toDouble());
    final errorThresholds = data.thresholdsFor((g) => g.errors.toDouble());
    final digThresholds = data.thresholdsFor((g) => g.digs.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Recent Form',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              _buildHeaderRow(context, colorScheme),
              // Data rows
              ...data.games.map((game) => _buildGameRow(
                    context,
                    game,
                    hitThresholds,
                    aceThresholds,
                    errorThresholds,
                    digThresholds,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context, ColorScheme colorScheme) {
    const headers = ['Opponent', 'Result', 'Hit%', 'Aces', 'Errors', 'Digs'];
    const widths = [100.0, 52.0, 56.0, 52.0, 56.0, 52.0];

    return Row(
      children: List.generate(headers.length, (i) {
        return Container(
          width: widths[i],
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(
            headers[i],
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                ),
          ),
        );
      }),
    );
  }

  Widget _buildGameRow(
    BuildContext context,
    RecentFormGame game,
    (double, double) hitThresholds,
    (double, double) aceThresholds,
    (double, double) errorThresholds,
    (double, double) digThresholds,
  ) {
    final truncatedName = game.opponent.length > 12
        ? '${game.opponent.substring(0, 12)}…'
        : game.opponent;

    final hitPctStr =
        '.${(game.hittingPct.abs() * 1000).round().toString().padLeft(3, '0')}';
    final isNegative = game.hittingPct < 0;

    return InkWell(
      onTap: onTapGame != null ? () => onTapGame!(game.gameId) : null,
      child: Row(
        children: [
          // Opponent name
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Text(
              truncatedName,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Result badge
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: game.isWin
                    ? StatLineColors.pointScored.withAlpha(40)
                    : StatLineColors.pointLost.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                game.isWin ? 'W' : 'L',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: game.isWin
                      ? StatLineColors.pointScored
                      : StatLineColors.pointLost,
                ),
              ),
            ),
          ),
          // Hit% — for errors, lower is better, so invert color
          _statCell(context, isNegative ? '-$hitPctStr' : hitPctStr,
              game.hittingPct, hitThresholds, 56),
          // Aces — higher is better
          _statCell(context, '${game.aces}', game.aces.toDouble(),
              aceThresholds, 52),
          // Errors — lower is better (invert: high errors = red)
          _statCellInverted(context, '${game.errors}',
              game.errors.toDouble(), errorThresholds, 56),
          // Digs — higher is better
          _statCell(context, '${game.digs}', game.digs.toDouble(),
              digThresholds, 52),
        ],
      ),
    );
  }

  /// Color cell where higher value = green (better).
  Widget _statCell(BuildContext context, String label, double value,
      (double, double) thresholds, double width) {
    Color bg;
    if (value >= thresholds.$2) {
      bg = _greenBg;
    } else if (value <= thresholds.$1) {
      bg = _redBg;
    } else {
      bg = _yellowBg;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      color: bg,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
      ),
    );
  }

  /// Color cell where lower value = green (better), e.g., errors.
  Widget _statCellInverted(BuildContext context, String label, double value,
      (double, double) thresholds, double width) {
    Color bg;
    if (value <= thresholds.$1) {
      bg = _greenBg;
    } else if (value >= thresholds.$2) {
      bg = _redBg;
    } else {
      bg = _yellowBg;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      color: bg,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_on,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
          ),
          const SizedBox(height: 8),
          Text(
            'Need 3+ completed games to show form',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
          ),
        ],
      ),
    );
  }
}
