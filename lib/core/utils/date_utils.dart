/// core/utils
/// ==========
/// Contains small, shared helper functions that do not belong to a
/// specific feature or layer (e.g., formatting helpers, converters).
class AppDateUtils {
  /// Formats [dateTime] into a simple `YYYY-MM-DD` string.
  /// This is intentionally dependency-free (no intl package).
  static String formatDateYYYYMMDD(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
