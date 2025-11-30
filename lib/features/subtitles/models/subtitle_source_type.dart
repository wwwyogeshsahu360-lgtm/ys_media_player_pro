/// SubtitleSourceType
/// ==================
/// The origin of a subtitle track.
enum SubtitleSourceType {
  /// Subtitles that are muxed into the media file itself.
  embedded,

  /// Subtitles from a local file on disk (.srt/.vtt/.ass).
  localFile,

  /// Subtitles originally obtained from an online provider
  /// (usually downloaded and stored locally).
  online,
}

/// SubtitleFormat
/// ==============
/// Supported subtitle text formats.
enum SubtitleFormat {
  srt,
  vtt,
  ass,
}
