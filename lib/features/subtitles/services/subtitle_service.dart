import 'dart:io';

import '../../../shared/models/media_item.dart';
import '../../../shared/services/log_service.dart';
import '../models/subtitle_cue.dart';
import '../models/subtitle_track.dart';
import '../models/subtitle_source_type.dart';
import '../parsers/srt_parser.dart';
import '../parsers/vtt_parser.dart';
import '../parsers/ass_parser.dart';

/// SubtitleService
/// ===============
/// Responsible for discovering, loading and parsing subtitle tracks.
class SubtitleService {
  SubtitleService._internal();

  static final SubtitleService instance = SubtitleService._internal();

  /// Scan the media's directory for matching subtitle files.
  Future<List<SubtitleTrack>> findLocalSubtitlesFor(MediaItem media) async {
    final List<SubtitleTrack> tracks = [];

    try {
      final path = media.path;
      if (path.isEmpty) return const [];

      final mediaFile = File(path);
      if (!mediaFile.existsSync()) {
        return const [];
      }

      final dir = mediaFile.parent;
      final mediaName = _fileNameWithoutExtension(mediaFile.path);

      await for (final entity in dir.list()) {
        if (entity is! File) continue;

        final name = entity.uri.pathSegments.isNotEmpty
            ? entity.uri.pathSegments.last
            : '';
        final base = _fileNameWithoutExtension(name);
        final ext = _extension(name).toLowerCase();

        if (base != mediaName) continue;

        SubtitleFormat? format;
        if (ext == 'srt') {
          format = SubtitleFormat.srt;
        } else if (ext == 'vtt') {
          format = SubtitleFormat.vtt;
        } else if (ext == 'ass' || ext == 'ssa') {
          format = SubtitleFormat.ass;
        }

        if (format == null) continue;

        tracks.add(
          SubtitleTrack(
            id: entity.path,
            label: name,
            languageCode: null,
            sourceType: SubtitleSourceType.localFile,
            pathOrUrl: entity.path,
            format: format,
          ),
        );
      }
    } catch (e, st) {
      LogService.instance.logError(
        '[SubtitleService] findLocalSubtitlesFor error: $e',
        st,
      );
    }

    return tracks;
  }

  /// Choose a "best" local subtitle match, if any exist.
  Future<SubtitleTrack?> autoMatchSubtitle(MediaItem media) async {
    final candidates = await findLocalSubtitlesFor(media);
    if (candidates.isEmpty) return null;

    // Very simple heuristic: just return the first one.
    return candidates.first;
  }

  /// Load and parse a track from its [pathOrUrl] if it's a local file.
  Future<SubtitleTrack> loadAndParseTrack(SubtitleTrack track) async {
    List<SubtitleCue> cues = <SubtitleCue>[];

    try {
      if (track.sourceType == SubtitleSourceType.localFile ||
          track.sourceType == SubtitleSourceType.online) {
        final file = File(track.pathOrUrl);
        if (!file.existsSync()) {
          LogService.instance.log(
              '[SubtitleService] file does not exist: ${track.pathOrUrl}');
          return track;
        }

        final content = await file.readAsString();

        switch (track.format) {
          case SubtitleFormat.srt:
            cues = SrtParser.parse(content);
            break;
          case SubtitleFormat.vtt:
            cues = VttParser.parse(content);
            break;
          case SubtitleFormat.ass:
            cues = AssParser.parse(content);
            break;
        }
      }
    } catch (e, st) {
      LogService.instance.logError(
        '[SubtitleService] loadAndParseTrack error: $e',
        st,
      );
    }

    return track.copyWith(cues: cues);
  }

  String _fileNameWithoutExtension(String path) {
    final segments = path.split(Platform.pathSeparator);
    final fileName = segments.isNotEmpty ? segments.last : path;
    final dot = fileName.lastIndexOf('.');
    if (dot == -1) return fileName;
    return fileName.substring(0, dot);
  }

  String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1);
  }
}
