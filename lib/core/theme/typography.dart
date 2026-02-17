import 'package:flutter/material.dart';

/// Athletic typography system for StatLine.
class StatLineTypography {
  StatLineTypography._();

  static const String _fontFamily = 'Roboto';
  static const String _monoFontFamily = 'RobotoMono';

  // ── Headlines ──────────────────────────────────────────────────────────

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  // ── Titles ─────────────────────────────────────────────────────────────

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  // ── Body ───────────────────────────────────────────────────────────────

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  // ── Stat-specific styles ───────────────────────────────────────────────

  /// Bold monospace numbers for stat displays (kills, aces, etc.).
  static const TextStyle statNumber = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  /// Uppercase label beneath stat numbers.
  static const TextStyle statLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    // Applied via style — caller should set text to uppercase or use
    // a widget-level transform.
  );

  /// Extra-bold score display for live game view.
  static const TextStyle scoreDisplay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
  );

  // ── TextTheme helper ───────────────────────────────────────────────────

  static TextTheme get textTheme => const TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelSmall: statLabel,
      );
}
