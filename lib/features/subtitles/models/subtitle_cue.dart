import 'package:flutter/foundation.dart';

/// SubtitleCue
/// ===========
/// Represents a single subtitle line with start/end times and text.
class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  /// Optional cue-level styling.
  final bool italic;
  final bool bold;

  /// Relative vertical position hint (0.0 = top, 1.0 = bottom).
  final double? linePosition;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
    this.italic = false,
    this.bold = false,
    this.linePosition,
  }) : assert(start <= end, 'start must be <= end');

  SubtitleCue copyWith({
    Duration? start,
    Duration? end,
    String? text,
    bool? italic,
    bool? bold,
    double? linePosition,
  }) {
    return SubtitleCue(
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
      italic: italic ?? this.italic,
      bold: bold ?? this.bold,
      linePosition: linePosition ?? this.linePosition,
    );
  }

  @override
  String toString() {
    return 'SubtitleCue(start: $start, end: $end, text: ${describeEnum(italic ? 'i' : 'n')})';
  }
}
