// lib/features/streaming/impl/hls_manifest_parser.dart
import '../domain/stream_manifest.dart';
import '../domain/stream_representation.dart';
import '../domain/stream_subtitle_track.dart';
import '../domain/drm/drm_models.dart';
import '../../../shared/services/log_service.dart';

/// Very lightweight / safe HLS manifest parser.
/// For now we do NOT hit network or fully parse .m3u8.
/// We just build a few mock representations so the app can run.
class HlsManifestParser {
  HlsManifestParser._internal();

  static final HlsManifestParser instance = HlsManifestParser._internal();

  Future<StreamManifest> parse(Uri uri, {String? content}) async {
    // In a real implementation you’d parse [content] and extract variants.
    // For now, we just create some “fake but valid” variants for debugging.
    final LogService log = LogService.instance;
    log.log('[HlsManifestParser] parse called for $uri');

    final List<StreamRepresentation> video = <StreamRepresentation>[
      StreamRepresentation(
        id: 'hls-360p',
        url: uri.toString(),
        bandwidth: 800 * 1000,
        width: 640,
        height: 360,
        mimeType: 'application/vnd.apple.mpegurl',
        codecs: 'avc1.42E01E,mp4a.40.2',
      ),
      StreamRepresentation(
        id: 'hls-720p',
        url: uri.toString(),
        bandwidth: 2500 * 1000,
        width: 1280,
        height: 720,
        mimeType: 'application/vnd.apple.mpegurl',
        codecs: 'avc1.4D401F,mp4a.40.2',
      ),
      StreamRepresentation(
        id: 'hls-1080p',
        url: uri.toString(),
        bandwidth: 5000 * 1000,
        width: 1920,
        height: 1080,
        mimeType: 'application/vnd.apple.mpegurl',
        codecs: 'avc1.640028,mp4a.40.2',
      ),
    ];

    final List<StreamSubtitleTrack> subs = <StreamSubtitleTrack>[
      StreamSubtitleTrack(
        id: 'sub-en',
        url: uri.toString(), // placeholder
        language: 'en',
        mimeType: 'text/vtt',
      ),
    ];

    final List<DrmSignal> drmSignals = <DrmSignal>[];

    return StreamManifest(
      type: StreamManifestType.hls,
      video: video,
      audio: <StreamRepresentation>[],
      subtitles: subs,
      drmSignals: drmSignals,
    );
  }
}
