import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/media_item.dart';
import 'log_service.dart';

/// ThumbnailService
/// =================
/// Provides thumbnail generation for video media using the `video_thumbnail`
/// plugin. Results are cached in-memory to avoid repeated work.
///
/// If thumbnail generation fails for any reason, `null` is returned and a
/// default icon should be shown in the UI.
class ThumbnailService {
  ThumbnailService._internal();

  static final ThumbnailService instance = ThumbnailService._internal();

  /// Cache of mediaId -> thumbnailPath (or null if generation failed).
  final Map<String, String?> _cache = <String, String?>{};

  /// Tracks in-flight thumbnail generation futures to avoid redundant work.
  final Map<String, Future<String?>> _inFlight =
  <String, Future<String?>>{};

  /// Returns a local file path for a thumbnail corresponding to the given
  /// [MediaItem], or null if thumbnail generation failed or is not possible.
  ///
  /// Thumbnail generation is done asynchronously and cached. Subsequent calls
  /// for the same media item id will re-use cached results or in-flight work.
  Future<String?> getThumbnailPathForMedia(MediaItem item) async {
    final String key = item.id;

    // 1) Return from cache if present (including null for failed attempts).
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    // 2) If generation is already in-flight for this item, return the same
    //    Future to avoid duplicate processing.
    final existingFuture = _inFlight[key];
    if (existingFuture != null) {
      return existingFuture;
    }

    // 3) Start generation.
    final Future<String?> future = _generateThumbnail(item);
    _inFlight[key] = future;

    future.then((String? result) {
      _cache[key] = result;
      _inFlight.remove(key);
    });

    return future;
  }

  Future<String?> _generateThumbnail(MediaItem item) async {
    final String path = item.path;
    if (path.isEmpty) {
      _cache[item.id] = null;
      return null;
    }

    try {
      final String? thumbPath = await VideoThumbnail.thumbnailFile(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 320,
        maxWidth: 320,
        quality: 70,
      );

      if (thumbPath == null) {
        LogService.instance.log(
          'ThumbnailService: thumbnailFile returned null for ${item.id}',
        );
      } else {
        LogService.instance.log(
          'ThumbnailService: generated thumbnail for ${item.id} at $thumbPath',
        );
      }

      return thumbPath;
    } catch (e, stackTrace) {
      LogService.instance.logError(
        'ThumbnailService: failed to generate thumbnail for ${item.id}: $e',
        stackTrace,
      );
      return null;
    }
  }

  /// Clears all in-memory thumbnail cache entries.
  void clearCache() {
    _cache.clear();
    _inFlight.clear();
  }
}
