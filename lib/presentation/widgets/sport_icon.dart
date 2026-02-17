import 'package:flutter/material.dart';

/// Widget that displays a sport-specific Material icon.
class SportIcon extends StatelessWidget {
  final String sport;
  final double size;
  final Color? color;

  const SportIcon({
    super.key,
    required this.sport,
    this.size = 24.0,
    this.color,
  });

  static IconData iconForSport(String sport) {
    return switch (sport.toLowerCase()) {
      'volleyball' => Icons.sports_volleyball,
      'basketball' => Icons.sports_basketball,
      'baseball' => Icons.sports_baseball,
      'softball' || 'slowpitch' => Icons.sports_baseball,
      'football' => Icons.sports_football,
      'soccer' => Icons.sports_soccer,
      _ => Icons.sports,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconForSport(sport),
      size: size,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
