import '../services/log_service.dart';

/// CrashReporter
/// =============
/// Abstraction for crash reporting providers.
abstract class CrashReporter {
  Future<void> init();
  Future<void> reportError(
      Object error,
      StackTrace stack, {
        Map<String, dynamic>? context,
      });
  Future<void> setUser(String? id);
}

/// MockCrashReporter
/// =================
/// Writes crash info to logs (and can later write to disk if needed).
class MockCrashReporter implements CrashReporter {
  MockCrashReporter._internal();

  static final MockCrashReporter instance = MockCrashReporter._internal();

  final LogService _log = LogService.instance;

  @override
  Future<void> init() async {
    _log.log('[CrashReporter] MockCrashReporter initialized');
  }

  @override
  Future<void> reportError(
      Object error,
      StackTrace stack, {
        Map<String, dynamic>? context,
      }) async {
    _log.logError('[CrashReporter] Caught error: $error\nContext: $context', stack);
  }

  @override
  Future<void> setUser(String? id) async {
    _log.log('[CrashReporter] setUser: $id');
  }
}
