import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../shared/models/media_item.dart';
import '../../../shared/services/log_service.dart';
import '../models/subtitle_track.dart';
import '../models/subtitle_source_type.dart';

/// OnlineSubtitleProvider (Mock)
/// =============================
/// This is a mock provider that simulates searching & downloading
/// online subtitles. No real HTTP calls are made.
class OnlineSubtitleProvider {
  OnlineSubtitleProvider._internal();

  static final OnlineSubtitleProvider instance =
  OnlineSubtitleProvider._internal();

  Future<List<SubtitleTrack>> searchOnline(MediaItem media) async {
    // Simulate 2–3 language options
    final baseId = media.fileName;
    return <SubtitleTrack>[
      SubtitleTrack(
        id: 'online_en_$baseId',
        label: 'English (Online)',
        languageCode: 'en',
        sourceType: SubtitleSourceType.online,
        pathOrUrl: 'mock://online/english/$baseId',
        format: SubtitleFormat.srt,
      ),
      SubtitleTrack(
        id: 'online_hi_$baseId',
        label: 'Hindi (Online)',
        languageCode: 'hi',
        sourceType: SubtitleSourceType.online,
        pathOrUrl: 'mock://online/hindi/$baseId',
        format: SubtitleFormat.srt,
      ),
    ];
  }

  /// "Download" the subtitle by writing a simple SRT file into cache
  /// and returning an updated local track.
  Future<SubtitleTrack> downloadToLocalFile(
      SubtitleTrack track,
      MediaItem media,
      ) async {
    try {
      final dir = await getTemporaryDirectory();
      final subDir = Directory('${dir.path}/subtitles');
      if (!subDir.existsSync()) {
        subDir.createSync(recursive: true);
      }

      final fileName = '${media.fileName}_${track.languageCode ?? 'sub'}.srt';
      final file = File('${subDir.path}/$fileName');

      // Very basic dummy SRT content
      final content = '''
1
00:00:01,000 --> 00:00:04,000
${track.label} subtitle demo for ${media.fileName}

2
00:00:05,000 --> 00:00:08,000
YS Media Player Pro — Online Mock Subtitle
''';

      await file.writeAsString(content);

      return track.copyWith(
        sourceType: SubtitleSourceType.localFile,
        pathOrUrl: file.path,
      );
    } catch (e, st) {
      LogService.instance
          .logError('[OnlineSubtitleProvider] download error: $e', st);
      return track;
    }
  }
}
