import 'package:flutter/material.dart';
import '../../core/theme/typography.dart';

/// Reusable stat display card with label, value, and optional trend indicator.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final TrendDirection trend;
  final Color? valueColor;
  final double? width;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.trend = TrendDirection.neutral,
    this.valueColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = valueColor ?? colorScheme.onSurface;

    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width != null ? 8 : 16,
            vertical: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: StatLineTypography.statNumber.copyWith(
                        color: effectiveColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trend != TrendDirection.neutral) ...[
                    const SizedBox(width: 4),
                    Icon(
                      trend == TrendDirection.up
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: trend == TrendDirection.up
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: StatLineTypography.statLabel.copyWith(
                  color: colorScheme.onSurface.withAlpha(153),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TrendDirection { up, down, neutral }
