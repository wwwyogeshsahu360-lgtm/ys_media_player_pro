/// AppFormatUtils
/// ==============
/// Stateless utility helpers for formatting durations and file sizes into
/// user-facing strings. Kept dependency-free to allow reuse across layers.
class AppFormatUtils {
  AppFormatUtils._();

  /// Formats [duration] into "HH:MM:SS" when hours are present,
  /// otherwise "MM:SS".
  static String durationToHmsString(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hoursStr = hours.toString().padLeft(2, '0');
      return '$hoursStr:$minutesStr:$secondsStr';
    }

    return '$minutesStr:$secondsStr';
  }

  /// Formats byte counts into a human-readable string such as "12.3 MB",
  /// "456 KB" or "980 B".
  static String formatBytes(int bytes) {
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    const int tb = gb * 1024;

    if (bytes >= tb) {
      final value = bytes / tb;
      return '${value.toStringAsFixed(2)} TB';
    } else if (bytes >= gb) {
      final value = bytes / gb;
      return '${value.toStringAsFixed(2)} GB';
    } else if (bytes >= mb) {
      final value = bytes / mb;
      return '${value.toStringAsFixed(1)} MB';
    } else if (bytes >= kb) {
      final value = bytes / kb;
      return '${value.toStringAsFixed(0)} KB';
    }

    return '$bytes B';
  }
}
