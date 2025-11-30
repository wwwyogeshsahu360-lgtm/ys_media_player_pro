// lib/shared/services/accessibility_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'log_service.dart';

/// AccessibilityService
/// =====================
/// Stores user preference for text scale and other a11y toggles.
enum TextScalePreset {
  small,
  normal,
  large,
}

class AccessibilityService extends ChangeNotifier {
  AccessibilityService._internal();

  static final AccessibilityService instance =
  AccessibilityService._internal();

  static const String _kTextScaleKey = 'ys_text_scale_preset';

  TextScalePreset _preset = TextScalePreset.normal;

  TextScalePreset get preset => _preset;

  double get textScaleFactor {
    switch (_preset) {
      case TextScalePreset.small:
        return 0.9;
      case TextScalePreset.normal:
        return 1.0;
      case TextScalePreset.large:
        return 1.2;
    }
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kTextScaleKey);
      if (raw != null) {
        _preset = TextScalePreset.values
            .firstWhere((e) => e.name == raw, orElse: () {
          return TextScalePreset.normal;
        });
      }
      LogService.instance
          .log('[AccessibilityService] init preset=$_preset');
    } catch (e, st) {
      LogService.instance
          .logError('[AccessibilityService] init error: $e', st);
    }
  }

  Future<void> setPreset(TextScalePreset preset) async {
    _preset = preset;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTextScaleKey, preset.name);
      LogService.instance
          .log('[AccessibilityService] setPreset=$preset');
    } catch (e, st) {
      LogService.instance
          .logError('[AccessibilityService] setPreset error: $e', st);
    }
  }
}
