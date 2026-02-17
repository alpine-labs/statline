import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Material 3 theme configuration for StatLine.
class StatLineTheme {
  StatLineTheme._();

  // Minimum touch target size (56 × 56 dp).
  static const double _minTouchTarget = 56.0;

  // ── Light theme ────────────────────────────────────────────────────────

  static ThemeData lightTheme() {
    final colorScheme = StatLineColors.lightColorScheme;
    return _buildTheme(colorScheme);
  }

  // ── Dark theme ─────────────────────────────────────────────────────────

  static ThemeData darkTheme() {
    final colorScheme = StatLineColors.darkColorScheme;
    return _buildTheme(colorScheme);
  }

  // ── Game mode ──────────────────────────────────────────────────────────

  /// Optimized dark theme for live game stat entry.
  /// High contrast text, reduced glare, larger touch targets.
  static ThemeData gameMode() {
    final colorScheme = StatLineColors.gameModeColorScheme;
    return _buildTheme(colorScheme).copyWith(
      // Even higher contrast text for outdoor / bright-light use.
      textTheme: StatLineTypography.textTheme.apply(
        bodyColor: const Color(0xFFF5F5F5),
        displayColor: const Color(0xFFFFFFFF),
      ),
      // Slightly larger minimum button size for fast tapping.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 64),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: StatLineTypography.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Reduced surface brightness to cut glare.
      scaffoldBackgroundColor: const Color(0xFF0E0E0E),
    );
  }

  // ── Shared builder ─────────────────────────────────────────────────────

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? StatLineColors.darkBackground : StatLineColors.lightBackground,
      textTheme: StatLineTypography.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),

      // ── AppBar ───────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: StatLineTypography.titleLarge.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // ── Elevated buttons ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(_minTouchTarget, _minTouchTarget),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: StatLineTypography.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Text buttons ─────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(_minTouchTarget, _minTouchTarget),
          foregroundColor: colorScheme.primary,
          textStyle: StatLineTypography.titleMedium,
        ),
      ),

      // ── Outlined buttons ─────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(_minTouchTarget, _minTouchTarget),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          textStyle: StatLineTypography.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Icon buttons ─────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(_minTouchTarget, _minTouchTarget),
        ),
      ),

      // ── Floating action button ───────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── Input decoration ─────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surface.withAlpha(128)
            : colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withAlpha(31),
        thickness: 1,
      ),
    );
  }
}
