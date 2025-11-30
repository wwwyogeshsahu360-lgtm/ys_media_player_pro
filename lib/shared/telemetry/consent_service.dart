import 'package:shared_preferences/shared_preferences.dart';

import '../services/log_service.dart';

const String _kConsentTelemetry = 'ys_consent_telemetry';
const String _kConsentCrash = 'ys_consent_crash';
const String _kConsentDiagnostics = 'ys_consent_diagnostics';
const String _kConsentInitialized = 'ys_consent_initialized';

/// ConsentService
/// ==============
/// Holds user privacy preferences (telemetry, crash reporting, diagnostics).
class ConsentService {
  ConsentService._internal();

  static final ConsentService instance = ConsentService._internal();

  final LogService _log = LogService.instance;

  bool telemetryEnabled = false;
  bool crashReportingEnabled = false;
  bool shareDiagnostics = false;
  bool hasCompletedFirstRun = false;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    telemetryEnabled = prefs.getBool(_kConsentTelemetry) ?? false;
    crashReportingEnabled = prefs.getBool(_kConsentCrash) ?? false;
    shareDiagnostics = prefs.getBool(_kConsentDiagnostics) ?? false;
    hasCompletedFirstRun = prefs.getBool(_kConsentInitialized) ?? false;

    _log.log(
      '[ConsentService] init -> telemetry=$telemetryEnabled '
          'crash=$crashReportingEnabled diagnostics=$shareDiagnostics '
          'firstRunComplete=$hasCompletedFirstRun',
    );
  }

  Future<void> setConsent({
    bool? telemetry,
    bool? crash,
    bool? diagnostics,
    bool markCompleted = true,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (telemetry != null) {
      telemetryEnabled = telemetry;
      await prefs.setBool(_kConsentTelemetry, telemetry);
    }
    if (crash != null) {
      crashReportingEnabled = crash;
      await prefs.setBool(_kConsentCrash, crash);
    }
    if (diagnostics != null) {
      shareDiagnostics = diagnostics;
      await prefs.setBool(_kConsentDiagnostics, diagnostics);
    }
    if (markCompleted) {
      hasCompletedFirstRun = true;
      await prefs.setBool(_kConsentInitialized, true);
    }

    _log.log(
      '[ConsentService] Updated consent -> '
          'telemetry=$telemetryEnabled crash=$crashReportingEnabled '
          'diagnostics=$shareDiagnostics',
    );
  }

  /// Clear all consent info + flags (used from Settings "Clear diagnostics").
  Future<void> resetAndPurge() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kConsentTelemetry);
    await prefs.remove(_kConsentCrash);
    await prefs.remove(_kConsentDiagnostics);
    await prefs.remove(_kConsentInitialized);

    telemetryEnabled = false;
    crashReportingEnabled = false;
    shareDiagnostics = false;
    hasCompletedFirstRun = false;

    _log.log('[ConsentService] resetAndPurge completed');
  }
}
