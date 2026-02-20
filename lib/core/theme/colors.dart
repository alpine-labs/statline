import 'package:flutter/material.dart';

/// Nordic Muted color system for StatLine.
class StatLineColors {
  StatLineColors._();

  // ── Nordic Muted palette ───────────────────────────────────────────────
  static const Color nordicSlate = Color(0xFF555B73);
  static const Color nordicCream = Color(0xFFE0DFD3);
  static const Color nordicSage = Color(0xFFC0BFAE);
  static const Color nordicGray = Color(0xFFB4B7BD);
  static const Color nordicMedium = Color(0xFF82858E);

  // ── Branding ────────────────────────────────────────────────────────────
  static const Color logoGreen = Color(0xFF4A6355);
  static const Color darkBackground = Color(0xFF1A1C24);
  static const Color darkSurface = Color(0xFF252833);
  static const Color primaryAccent = nordicSlate;
  static const Color secondaryAccent = nordicSage;

  // ── Scoring feedback ───────────────────────────────────────────────────
  static const Color pointScored = Color(0xFF4CAF50);
  static const Color pointLost = Color(0xFFEF5350);

  // ── Light mode ─────────────────────────────────────────────────────────
  static const Color lightBackground = nordicCream;
  static const Color lightSurface = Color(0xFFF0EFE6);

  // ── Neutral / text ─────────────────────────────────────────────────────
  static const Color onDarkBackground = nordicCream;
  static const Color onLightBackground = Color(0xFF2C2E36);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color disabled = nordicGray;

  // ── Per-sport accent colors ────────────────────────────────────────────
  static const Map<String, Color> sportAccents = {
    'volleyball': nordicSlate,
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
        primary: nordicSlate,
        onPrimary: onPrimary,
        secondary: nordicSage,
        onSecondary: onLightBackground,
        tertiary: nordicMedium,
        onTertiary: onPrimary,
        error: pointLost,
        onError: onPrimary,
        surface: lightSurface,
        onSurface: onLightBackground,
        surfaceContainerHighest: nordicCream,
        surfaceContainerLow: Color(0xFFEAE9DD),
        outline: nordicGray,
      );

  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: nordicSage,
        onPrimary: onLightBackground,
        secondary: nordicSlate,
        onSecondary: onPrimary,
        tertiary: nordicGray,
        onTertiary: onLightBackground,
        error: pointLost,
        onError: onPrimary,
        surface: darkSurface,
        onSurface: onDarkBackground,
        surfaceContainerHighest: Color(0xFF323542),
        surfaceContainerLow: Color(0xFF2A2D38),
        outline: nordicMedium,
      );

  /// High-contrast dark scheme optimized for live game stat entry.
  static ColorScheme get gameModeColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: nordicSage,
        onPrimary: onLightBackground,
        secondary: nordicSlate,
        onSecondary: onPrimary,
        error: pointLost,
        onError: onPrimary,
        surface: Color(0xFF1A1A1A),
        onSurface: Color(0xFFF5F5F5),
      );
}
