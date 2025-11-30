import 'package:flutter/foundation.dart';

import '../models/subtitle_cue.dart';
import '../../../shared/services/log_service.dart';

/// SrtParser
/// =========
/// Simple SRT parser with basic robustness for malformed files.
class SrtParser {
  static final RegExp _timeRegExp = RegExp(
    r'(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})',
  );

  static List<SubtitleCue> parse(String content) {
    final List<SubtitleCue> cues = [];

    try {
      final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final blocks = normalized.split(RegExp(r'\n\s*\n'));

      for (final block in blocks) {
        final lines = block.trim().split('\n');
        if (lines.length < 2) continue;

        int index = 0;

        // Optional numeric index line
        if (RegExp(r'^\d+$').hasMatch(lines[0].trim())) {
          index++;
        }

        if (index >= lines.length) continue;

        final timeLine = lines[index].trim();
        final match = _timeRegExp.firstMatch(timeLine);
        if (match == null) continue;

        final start = _parseTime(
          match.group(1),
          match.group(2),
          match.group(3),
          match.group(4),
        );
        final end = _parseTime(
          match.group(5),
          match.group(6),
          match.group(7),
          match.group(8),
        );

        final textLines = lines.sublist(index + 1);
        final text = textLines.join('\n').trim();
        if (text.isEmpty) continue;

        cues.add(
          SubtitleCue(
            start: start,
            end: end,
            text: text,
          ),
        );
      }
    } catch (e, st) {
      LogService.instance.logError('[SrtParser] parse error: $e', st);
    }

    return cues;
  }

  static Duration _parseTime(
      String? h,
      String? m,
      String? s,
      String? ms,
      ) {
    final hh = int.tryParse(h ?? '0') ?? 0;
    final mm = int.tryParse(m ?? '0') ?? 0;
    final ss = int.tryParse(s ?? '0') ?? 0;
    final mss = int.tryParse(ms ?? '0') ?? 0;
    return Duration(hours: hh, minutes: mm, seconds: ss, milliseconds: mss);
  }
}
