import '../../../shared/models/media_item.dart';

/// MediaSourceEntity
/// =================
/// Lightweight representation of a media source (local or network).
class MediaSourceEntity {
  const MediaSourceEntity({
    required this.uri,
    required this.isNetwork,
  });

  /// Normalized URI/path for the backend (file path or http(s) URL).
  final String uri;

  /// True if [uri] points to a network resource.
  final bool isNetwork;
}

/// MediaSourceBuilder
/// ==================
/// Utility to normalize MediaItem paths into a backend-friendly source.
class MediaSourceBuilder {
  const MediaSourceBuilder();

  MediaSourceEntity build(MediaItem item) {
    final String raw = item.path.trim();
    final bool isNetwork =
        raw.startsWith('http://') || raw.startsWith('https://');

    // For now, we simply pass through the path/URL. In future ExoPlayer/AVPlayer
    // integration, this is where DRM, headers, etc. can be configured.
    return MediaSourceEntity(uri: raw, isNetwork: isNetwork);
  }
}
