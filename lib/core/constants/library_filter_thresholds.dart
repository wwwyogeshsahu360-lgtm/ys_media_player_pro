/// Threshold constants used for library filters.
///
/// These can be tuned later to match UX expectations (e.g. MX/KM style).
class LibraryFilterThresholds {
  /// How "recent" a video should be to appear in the Recent filter.
  /// Example: last 7 days.
  static const Duration recentVideoMaxAge = Duration(days: 7);

  /// Minimum duration for a video to be considered "long".
  /// Example: 20 minutes or more.
  static const Duration longVideoThreshold = Duration(minutes: 20);

  /// Minimum file size (in bytes) for a video to be considered "large".
  /// Example: 300 MB.
  static const int largeVideoThresholdBytes = 300 * 1024 * 1024;
}
