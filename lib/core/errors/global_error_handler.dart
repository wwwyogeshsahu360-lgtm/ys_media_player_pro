import 'package:flutter/foundation.dart';

import '../../shared/services/log_service.dart';
import '../../shared/services/consent_service.dart';
import '../../shared/telemetry/crash_reporter.dart';

/// GlobalErrorHandler
/// ==================
/// Wires Flutter and Zone errors to LogService + CrashReporter
/// (respecting user consent).
class GlobalErrorHandler {
  static LogService? _logService;
  static CrashReporter? _crashReporter;
  static ConsentService? _consentService;

  static void initialize({
    required LogService logService,
    CrashReporter? crashReporter,
    ConsentService? consentService,
  }) {
    _logService = logService;
    _crashReporter = crashReporter;
    _consentService = consentService;

    FlutterError.onError = (FlutterErrorDetails details) async {
      _logService?.logError(
        'FlutterError: ${details.exceptionAsString()}',
        details.stack,
      );

      final consent = _consentService;
      if (consent != null) {
        await consent.init();
        if (consent.crashReportingEnabled) {
          await _crashReporter?.reportError(
            details.exception,
            details.stack ?? StackTrace.current,
            context: <String, dynamic>{
              'library': details.library,
              'context': details.context?.toDescription(),
            },
          );
        }
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _logService?.logError('PlatformDispatcher error: $error', stack);
      final consent = _consentService;
      if (consent != null) {
        consent.init().then((_) async {
          if (consent.crashReportingEnabled) {
            await _crashReporter?.reportError(error, stack);
          }
        });
      }
      return true;
    };
  }
}
