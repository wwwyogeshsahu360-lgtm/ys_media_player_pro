import 'package:flutter/material.dart';

/// core/config
/// ===========
/// Holds global, app-wide configuration such as environment, theme mode,
/// feature flags, etc. This is a single source of truth for runtime config.
class AppConfig {
  AppConfig._internal();

  /// Singleton instance to be used across the app.
  static final AppConfig instance = AppConfig._internal();

  /// Current theme mode for the whole app.
  /// Default is dark for a media-player-like feel.
  ThemeMode themeMode = ThemeMode.dark;

  /// Current environment string - "dev", "staging", "prod", etc.
  final String environment = 'dev';

// Day 1: kept intentionally simple but ready for future expansion.
}
