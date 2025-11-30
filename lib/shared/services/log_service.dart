import 'dart:developer' as developer;

/// LogService
/// ==========
/// Central logger + small in-memory rotating buffer for diagnostics.
class LogService {
  LogService._internal();

  /// Singleton instance.
  static final LogService instance = LogService._internal();

  // In-memory buffer of last N log lines.
  static const int _maxBufferLines = 500;
  final List<String> _buffer = <String>[];

  List<String> get recentLogs => List<String>.unmodifiable(_buffer);

  void _addToBuffer(String level, String message) {
    final line = '[$level] $message';
    _buffer.add(line);
    if (_buffer.length > _maxBufferLines) {
      _buffer.removeRange(0, _buffer.length - _maxBufferLines);
    }
  }

  /// Simple info-level log.
  void log(String message) {
    _addToBuffer('INFO', message);
    developer.log(
      message,
      name: 'YSMediaPlayerPro',
    );
  }

  /// Error-level log with optional [StackTrace].
  void logError(String message, [StackTrace? stackTrace]) {
    _addToBuffer('ERROR', message);
    developer.log(
      message,
      name: 'YSMediaPlayerPro',
      error: message,
      stackTrace: stackTrace,
      level: 1000, // high level for errors
    );
  }
}
