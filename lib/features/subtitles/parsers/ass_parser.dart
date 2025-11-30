import '../models/subtitle_cue.dart';
import '../../../shared/services/log_service.dart';

/// AssParser
/// =========
/// Very simplified ASS/SSA parser:
/// - Reads [Events] section
/// - Parses Dialogue lines (Start, End, Text)
/// - Strips basic override tags like {\i1} etc.
class AssParser {
  static List<SubtitleCue> parse(String content) {
    final List<SubtitleCue> cues = [];

    try {
      final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final lines = normalized.split('\n');

      bool inEvents = false;
      List<String>? formatFields;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('[Events]')) {
          inEvents = true;
          continue;
        }

        if (!inEvents) continue;

        if (trimmed.startsWith('Format:')) {
          // Format: Layer, Start, End, Style, Name, MarginL,...
          final format = trimmed.substring('Format:'.length).split(',');
          formatFields = format.map((f) => f.trim().toLowerCase()).toList();
          continue;
        }

        if (trimmed.startsWith('Dialogue:')) {
          if (formatFields == null) continue;
          final payload = trimmed.substring('Dialogue:'.length).trim();
          final parts = payload.split(',');

          // We expect at least: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
          if (parts.length < 10) continue;

          final startIndex = formatFields.indexOf('start');
          final endIndex = formatFields.indexOf('end');
          final textIndex = formatFields.indexOf('text');

          if (startIndex == -1 || endIndex == -1 || textIndex == -1) continue;

          final startStr = parts[startIndex].trim();
          final endStr = parts[endIndex].trim();

          // Text may contain commas; join from textIndex onward
          final textParts = parts.sublist(textIndex);
          var text = textParts.join(',').trim();

          final start = _parseAssTime(startStr);
          final end = _parseAssTime(endStr);

          // Strip override tags {\...}
          text = text.replaceAll(RegExp(r'\{\\.*?\}'), '');
          text = text.replaceAll('\\N', '\n').trim();
          if (text.isEmpty) continue;

          cues.add(
            SubtitleCue(
              start: start,
              end: end,
              text: text,
            ),
          );
        }
      }
    } catch (e, st) {
      LogService.instance.logError('[AssParser] parse error: $e', st);
    }

    return cues;
  }

  static Duration _parseAssTime(String value) {
    // Example: 0:01:23.45
    final parts = value.split(':');
    if (parts.length != 3) return Duration.zero;

    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final secParts = parts[2].split('.');
    final s = int.tryParse(secParts[0]) ?? 0;
    final cs = secParts.length > 1 ? int.tryParse(secParts[1]) ?? 0 : 0;

    // centiseconds -> ms
    final ms = (cs * 10).clamp(0, 999);
    return Duration(hours: h, minutes: m, seconds: s, milliseconds: ms);
  }
}
