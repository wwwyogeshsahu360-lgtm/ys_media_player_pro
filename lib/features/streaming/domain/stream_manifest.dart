import 'stream_representation.dart';
import 'stream_subtitle_track.dart';
import 'drm/drm_models.dart';

enum StreamManifestType { dash, hls, unknown }

class StreamManifest {
  final StreamManifestType type;
  final List<StreamRepresentation> video;
  final List<StreamRepresentation> audio;
  final List<StreamSubtitleTrack> subtitles;
  final List<DrmSignal> drmSignals;

  StreamManifest({
    required this.type,
    required this.video,
    required this.audio,
    required this.subtitles,
    required this.drmSignals,
  });
}
