// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'tokens.dart';

/// -------------------------------------------
/// YS Media Player Pro – Unified Theme System
/// -------------------------------------------

/// Color palette used across themes.
class YSColors {
  static const Color primary = Color(0xFF3D5AFE);
  static const Color secondary = Color(0xFFFF4081);

  // High-contrast palette
  static const Color highContrastPrimary = Color(0xFF000000);
  static const Color highContrastSurface = Color(0xFFFFFFFF);
}

/// YSTheme extension (Day 16)
@immutable
class YSTheme extends ThemeExtension<YSTheme> {
  final Color accent;

  const YSTheme({required this.accent});

  @override
  YSTheme copyWith({Color? accent}) {
    return YSTheme(accent: accent ?? this.accent);
  }

  @override
  YSTheme lerp(ThemeExtension<YSTheme>? other, double t) {
    if (other is! YSTheme) return this;
    return YSTheme(
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// -------------------------------------------
/// AppTheme — Day 16 Complete Theme API
/// -------------------------------------------
class AppTheme {
  // PUBLIC API USED BY main.dart (MUST EXIST)
  static ThemeData get lightTheme => _buildLightTheme();
  static ThemeData get darkTheme => _buildDarkTheme();
  static ThemeData get highContrastLight => _buildHighContrastLightTheme();
  static ThemeData get highContrastDark => _buildHighContrastDarkTheme();

  // -------------------------------------------
  // INTERNAL BUILDERS
  // -------------------------------------------

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: YSColors.primary,

      iconTheme: IconThemeData(
        size: YSIconSizes.md,
        color: Colors.black87,
      ),

      // ✅ CardThemeData (not CardTheme)
      cardTheme: const CardThemeData(
        elevation: YSElevation.low,
        margin: EdgeInsets.all(YSSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(YSRadii.md),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(YSRadii.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: YSSpacing.lg,
            vertical: YSSpacing.md,
          ),
        ),
      ),

      extensions: const [
        YSTheme(accent: YSColors.secondary),
      ],
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: YSColors.primary,

      iconTheme: IconThemeData(
        size: YSIconSizes.md,
        color: Colors.white70,
      ),

      cardTheme: const CardThemeData(
        elevation: YSElevation.low,
        margin: EdgeInsets.all(YSSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(YSRadii.md),
          ),
        ),
      ),

      extensions: const [
        YSTheme(accent: YSColors.secondary),
      ],
    );
  }

  static ThemeData _buildHighContrastLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.highContrastLight(
        primary: YSColors.highContrastPrimary,
        surface: YSColors.highContrastSurface,
      ),

      iconTheme: const IconThemeData(
        size: YSIconSizes.md,
        color: Colors.black,
      ),

      cardTheme: const CardThemeData(
        elevation: YSElevation.high,
        margin: EdgeInsets.all(YSSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YSRadii.lg)),
        ),
      ),

      extensions: const [
        YSTheme(accent: YSColors.highContrastPrimary),
      ],
    );
  }

  static ThemeData _buildHighContrastDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.highContrastDark(
        primary: YSColors.highContrastPrimary,
        surface: Colors.black,
      ),

      iconTheme: const IconThemeData(
        size: YSIconSizes.md,
        color: Colors.white,
      ),

      cardTheme: const CardThemeData(
        elevation: YSElevation.high,
        margin: EdgeInsets.all(YSSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YSRadii.lg)),
        ),
      ),

      extensions: const [
        YSTheme(accent: Colors.white),
      ],
    );
  }
}
