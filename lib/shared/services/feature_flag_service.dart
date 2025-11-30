// lib/shared/services/feature_flag_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'log_service.dart';

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

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kFlagsKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> map =
        jsonDecode(raw) as Map<String, dynamic>;
        _flags
          ..clear()
          ..addAll(map);
      } catch (_) {
        // ignore malformed cache
      }
    }

    // Mock remote refresh on first init.
    await refreshFromRemote();
  }

  bool isEnabled(String key, {bool defaultValue = false}) {
    final dynamic value = _flags[key];
    if (value is bool) return value;
    return defaultValue;
  }

  String getString(String key, {String defaultValue = ''}) {
    final dynamic value = _flags[key];
    if (value is String) return value;
    return defaultValue;
  }

  int getInt(String key, {int defaultValue = 0}) {
    final dynamic value = _flags[key];
    if (value is int) return value;
    return defaultValue;
  }

  /// Percentage rollout, deterministic based on [userId].
  bool isEnabledForUser(
      String key,
      String userId, {
        double rolloutPercent = 50,
      }) {
    final dynamic suffix = _flags['${key}_rollout'] ?? rolloutPercent;
    final double percent =
    (suffix is num) ? suffix.toDouble() : rolloutPercent;
    final int hash = userId.hashCode & 0x7fffffff;
    final int bucket = hash % 100;
    return bucket < percent;
  }

  Future<void> refreshFromRemote() async {
    // Mock remote config: enable telemetry debug screen in debug builds.
    _flags['settings.debug.telemetry'] = true;
    _flags['ui.new_settings_layout'] = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFlagsKey, jsonEncode(_flags));

    LogService.instance
        .log('[FeatureFlagService] Refreshed flags: $_flags');
  }

  /// Used by debug screens to inspect all flags.
  Map<String, dynamic> dumpFlags() =>
      Map<String, dynamic>.unmodifiable(_flags);
}
