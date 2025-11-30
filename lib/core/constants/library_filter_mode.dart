/// LibraryFilterMode
/// ==================
/// Global modes that define how the video library should be filtered.
///
/// - all    → No extra filter, show all videos.
/// - recent → Videos that are recently added/modified (by date).
/// - long   → Videos whose duration is above a threshold (e.g. 20+ minutes).
/// - large  → Videos whose file size is above a threshold (e.g. 300+ MB).
enum LibraryFilterMode {
  all,
  recent,
  long,
  large,
}
