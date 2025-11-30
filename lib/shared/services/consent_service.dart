import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// ConsentService
/// ==============
/// Manages user consent for:
/// - Telemetry (analytics)
/// - Crash reporting
/// - Diagnostic logs sharing
///
/// Default: everything OFF until user explicitly opts in.
class ConsentService {
  ConsentService._internal();

  static final ConsentService instance = ConsentService._internal();

  static const String _kTelemetryKey = 'ys_consent_telemetry_v1';
  static const String _kCrashKey = 'ys_consent_crash_v1';
  static const String _kDiagnosticsKey = 'ys_consent_diagnostics_v1';
  static const String _kHasAskedKey = 'ys_consent_has_asked_v1';

  bool _initialized = false;

  bool _telemetryEnabled = false;
  bool _crashEnabled = false;
  bool _diagnosticsEnabled = false;
  bool _hasAsked = false;

  bool get telemetryEnabled => _telemetryEnabled;
  bool get crashReportingEnabled => _crashEnabled;
  bool get shareDiagnostics => _diagnosticsEnabled;
  bool get hasAskedConsentOnce => _hasAsked;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _telemetryEnabled = prefs.getBool(_kTelemetryKey) ?? false;
    _crashEnabled = prefs.getBool(_kCrashKey) ?? false;
    _diagnosticsEnabled = prefs.getBool(_kDiagnosticsKey) ?? false;
    _hasAsked = prefs.getBool(_kHasAskedKey) ?? false;
  }

  Future<void> setConsent({
    required bool telemetry,
    required bool crash,
    required bool diagnostics,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _telemetryEnabled = telemetry;
    _crashEnabled = crash;
    _diagnosticsEnabled = diagnostics;
    _hasAsked = true;

    await prefs.setBool(_kTelemetryKey, telemetry);
    await prefs.setBool(_kCrashKey, crash);
    await prefs.setBool(_kDiagnosticsKey, diagnostics);
    await prefs.setBool(_kHasAskedKey, true);
  }

  /// Reset all consent flags and optionally purge local diagnostics/telemetry.
  Future<void> resetAndPurge() async {
    final prefs = await SharedPreferences.getInstance();

    _telemetryEnabled = false;
    _crashEnabled = false;
    _diagnosticsEnabled = false;
    _hasAsked = false;

    await prefs.remove(_kTelemetryKey);
    await prefs.remove(_kCrashKey);
    await prefs.remove(_kDiagnosticsKey);
    await prefs.remove(_kHasAskedKey);
  }
}
