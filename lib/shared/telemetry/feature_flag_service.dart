import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/log_service.dart';

const String _kFlagsKey = 'ys_feature_flags_v1';

/// FeatureFlagService
/// ==================
/// Simple local feature flags with optional percentage rollout.
class FeatureFlagService {
  FeatureFlagService._internal();

  static final FeatureFlagService instance = FeatureFlagService._internal();

  final Map<String, dynamic> _flags = <String, dynamic>{};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFlagsKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _flags.clear();
        _flags.addAll(map);
      } catch (_) {}
    }

    // Mock remote refresh on first init
    await refreshFromRemote();
  }

  bool isEnabled(String key, {bool defaultValue = false}) {
    final value = _flags[key];
    if (value is bool) return value;
    return defaultValue;
  }

  String getString(String key, {String defaultValue = ''}) {
    final value = _flags[key];
    if (value is String) return value;
    return defaultValue;
  }

  int getInt(String key, {int defaultValue = 0}) {
    final value = _flags[key];
    if (value is int) return value;
    return defaultValue;
  }

  /// Percentage rollout, deterministic based on [userId].
  bool isEnabledForUser(String key, String userId,
      {double rolloutPercent = 50}) {
    final suffix = _flags['${key}_rollout'] ?? rolloutPercent;
    final percent = (suffix is num) ? suffix.toDouble() : rolloutPercent;
    final hash = userId.hashCode & 0x7fffffff;
    final bucket = hash % 100;
    return bucket < percent;
  }

  Future<void> refreshFromRemote() async {
    // Mock remote config: enable telemetry debug screen in debug builds.
    _flags['settings.debug.telemetry'] = true;
    _flags['ui.new_settings_layout'] = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFlagsKey, jsonEncode(_flags));

    LogService.instance
        .log('[FeatureFlagService] Refreshed flags: $_flags');
  }

  // ============================================================
  //              🔥 ADDED METHOD — FIXES LAST ERROR 🔥
  // ============================================================
  /// Returns all stored feature flags for debug UI.
  Map<String, dynamic> dumpFlags() {
    return Map<String, dynamic>.from(_flags);
  }
}
