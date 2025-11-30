// lib/shared/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import 'log_service.dart';

/// ThemeService
/// ============
/// Controls ThemeMode and high-contrast flag.
/// Uses SharedPreferences for persistence.
class ThemeService extends ChangeNotifier {
  ThemeService._internal();

  static final ThemeService instance = ThemeService._internal();

  static const String _kThemeModeKey = 'ys_theme_mode';
  static const String _kHighContrastKey = 'ys_theme_high_contrast';

  ThemeMode _themeMode = ThemeMode.system;
  bool _highContrast = false;

  ThemeMode get themeMode => _themeMode;
  bool get highContrast => _highContrast;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? modeStr = prefs.getString(_kThemeModeKey);
      final bool hc = prefs.getBool(_kHighContrastKey) ?? false;

      _highContrast = hc;

      if (modeStr != null) {
        _themeMode = _parseThemeMode(modeStr);
      } else {
        // Default from AppConfig (Day-1 style).
        _themeMode = AppConfig.instance.themeMode;
      }
      LogService.instance
          .log('[ThemeService] init themeMode=$_themeMode highContrast=$_highContrast');
    } catch (e, st) {
      LogService.instance
          .logError('[ThemeService] init error: $e', st);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeModeKey, _themeMode.name);
      LogService.instance.log('[ThemeService] setThemeMode=$mode');
    } catch (e, st) {
      LogService.instance
          .logError('[ThemeService] setThemeMode error: $e', st);
    }
  }

  Future<void> setHighContrast(bool enabled) async {
    _highContrast = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHighContrastKey, enabled);
      LogService.instance
          .log('[ThemeService] setHighContrast=$enabled');
    } catch (e, st) {
      LogService.instance
          .logError('[ThemeService] setHighContrast error: $e', st);
    }
  }

  ThemeMode _parseThemeMode(String v) {
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
