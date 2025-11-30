import '../services/log_service.dart';
import 'telemetry_local_store.dart';

/// LogsBundle
/// ==========
/// Collects recent logs + telemetry buffer summary for feedback/crash reports.
class LogsBundle {
  final String logText;
  final int logLines;
  final int telemetryCount;

  LogsBundle({
    required this.logText,
    required this.logLines,
    required this.telemetryCount,
  });

  static Future<LogsBundle> collect() async {
    final logService = LogService.instance;
    final telemetryStore = TelemetryLocalStore.instance;

    final buffer = logService.recentLogs;
    final logLines = buffer.length;
    final logText = buffer.join('\n');
    final telemetryCount = telemetryStore.buffer.length;

    return LogsBundle(
      logText: logText,
      logLines: logLines,
      telemetryCount: telemetryCount,
    );
  }
}
