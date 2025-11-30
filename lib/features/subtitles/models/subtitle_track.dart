import 'subtitle_cue.dart';
import 'subtitle_source_type.dart';

/// SubtitleTrack
/// =============
/// A selectable subtitle track with associated cues.
class SubtitleTrack {
  /// Unique ID within this app (can be path, url, or generated).
  final String id;

  /// Human readable label, e.g. "English", "Hindi".
  final String label;

  /// Optional BCP-47 language code, e.g. "en", "hi".
  final String? languageCode;

  final SubtitleSourceType sourceType;
  final String pathOrUrl;
  final bool isDefault;
  final String? encoding;
  final SubtitleFormat format;

  /// Parsed cues (may be empty if not loaded yet).
  final List<SubtitleCue> cues;

  const SubtitleTrack({
    required this.id,
    required this.label,
    required this.sourceType,
    required this.pathOrUrl,
    required this.format,
    this.languageCode,
    this.isDefault = false,
    this.encoding,
    this.cues = const <SubtitleCue>[],
  });

  SubtitleTrack copyWith({
    String? id,
    String? label,
    String? languageCode,
    SubtitleSourceType? sourceType,
    String? pathOrUrl,
    bool? isDefault,
    String? encoding,
    SubtitleFormat? format,
    List<SubtitleCue>? cues,
  }) {
    return SubtitleTrack(
      id: id ?? this.id,
      label: label ?? this.label,
      languageCode: languageCode ?? this.languageCode,
      sourceType: sourceType ?? this.sourceType,
      pathOrUrl: pathOrUrl ?? this.pathOrUrl,
      isDefault: isDefault ?? this.isDefault,
      encoding: encoding ?? this.encoding,
      format: format ?? this.format,
      cues: cues ?? this.cues,
    );
  }

  @override
  String toString() {
    return 'SubtitleTrack(id: $id, label: $label, src: $sourceType, format: $format, cues: ${cues.length})';
  }
}
