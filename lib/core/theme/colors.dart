import 'package:flutter/material.dart';

/// Sport-themed color system for StatLine.
class StatLineColors {
  StatLineColors._();

  // ── Dark game mode colors ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color primaryAccent = Color(0xFFFF6B35); // volleyball orange
  static const Color secondaryAccent = Color(0xFF00B4D8); // teal

  // ── Scoring feedback ───────────────────────────────────────────────────
  static const Color pointScored = Color(0xFF4CAF50);
  static const Color pointLost = Color(0xFFEF5350);

  // ── Light mode ─────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // ── Neutral / text ─────────────────────────────────────────────────────
  static const Color onDarkBackground = Color(0xFFE0E0E0);
  static const Color onLightBackground = Color(0xFF212121);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color disabled = Color(0xFF9E9E9E);

  // ── Per-sport accent colors ────────────────────────────────────────────
  static const Map<String, Color> sportAccents = {
    'volleyball': Color(0xFFFF6B35),
    'basketball': Color(0xFF1565C0),
    'slowpitch': Color(0xFF2E7D32),
    'baseball': Color(0xFFC62828),
    'football': Color(0xFF5D4037),
  };

  /// Returns the accent color for a given sport identifier.
  ///
  /// Falls back to [primaryAccent] if the sport is not recognized.
  static Color forSport(String sportId) {
    return sportAccents[sportId.toLowerCase()] ?? primaryAccent;
  }

  // ── Color schemes ──────────────────────────────────────────────────────

  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: primaryAccent,
        onPrimary: onPrimary,
        secondary: secondaryAccent,
        onSecondary: onPrimary,
        error: pointLost,
        onError: onPrimary,
        surface: lightSurface,
        onSurface: onLightBackground,
      );

  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: primaryAccent,
        onPrimary: onPrimary,
        secondary: secondaryAccent,
        onSecondary: onPrimary,
        error: pointLost,
        onError: onPrimary,
        surface: darkSurface,
        onSurface: onDarkBackground,
      );

  /// High-contrast dark scheme optimized for live game stat entry.
  static ColorScheme get gameModeColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: primaryAccent,
        onPrimary: onPrimary,
        secondary: secondaryAccent,
        onSecondary: onPrimary,
        error: pointLost,
        onError: onPrimary,
        surface: Color(0xFF1A1A1A),
        onSurface: Color(0xFFF5F5F5),
      );
}
