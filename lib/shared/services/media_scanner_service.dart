import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../models/tag_item.dart';
import '../services/log_service.dart';
import '../services/permissions_service.dart';
import 'package:ys_media_player_pro/core/errors/media_permission_exception.dart';

/// MediaScannerService
/// ===================
/// Service responsible for scanning the device for video media using
/// Flutter plugins (photo_manager) and aggregating them into MediaItem
/// and FolderItem collections.
///
/// Day 6: uses real device scanning where supported, with permission
/// handling via PermissionsService. Mock methods are kept for testing.
class MediaScannerService {
  MediaScannerService._internal();

  static final MediaScannerService instance = MediaScannerService._internal();

  /// Performs a real scan of device videos using photo_manager.
  /// Requires media/storage permission; throws [MediaPermissionException]
  /// if permission is permanently denied, returns empty list if user
  /// denies non-permanently or platform is unsupported.
  Future<List<MediaItem>> performFullScan() async {
    final permissionsService = PermissionsService.instance;
    final logService = LogService.instance;

    try {
      final granted = await permissionsService.ensureMediaPermissionGranted();
      if (!granted) {
        logService.log(
          'MediaScannerService: media permission not granted, returning empty list',
        );
        return const <MediaItem>[];
      }
    } on MediaPermissionException {
      rethrow;
    } catch (e, stackTrace) {
      logService.logError(
        'MediaScannerService: unexpected error while requesting permission: $e',
        stackTrace,
      );
      return const <MediaItem>[];
    }

    if (kIsWeb) {
      LogService.instance
          .log('MediaScannerService: web platform, no local media scan');
      return const <MediaItem>[];
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      LogService.instance.log(
        'MediaScannerService: platform not supported for media scan',
      );
      return const <MediaItem>[];
    }

    final List<MediaItem> items = <MediaItem>[];

    // RequestType.video ensures only video assets are returned.
    final List<AssetPathEntity> paths =
    await PhotoManager.getAssetPathList(type: RequestType.video);

    for (final path in paths) {
      final int total = await path.assetCountAsync;
      if (total == 0) continue;

      // Load all assets in this path in a single page. For very large
      // libraries, paging can be introduced later.
      final List<AssetEntity> assets =
      await path.getAssetListPaged(page: 0, size: total);

      for (final asset in assets) {
        if (asset.type != AssetType.video) {
          continue;
        }

        // Asset information
        final String mediaId = asset.id;
        final String fileName = asset.title ?? 'Unknown';
        final Duration duration = Duration(seconds: asset.duration);
        final int width = asset.width;
        final int height = asset.height;
        final DateTime dateAdded = asset.createDateTime;
        final DateTime dateModified = asset.modifiedDateTime;
        final String relativePath = asset.relativePath ?? '/';

        // Try to obtain a real file path and size, if available.
        String effectivePath = relativePath;
        int fileSize = 0;

        try {
          final file = await asset.file; // May be null especially on iOS 14+
          if (file != null) {
            effectivePath = file.path;
            fileSize = await file.length();
          } else {
            effectivePath = '$relativePath$fileName';
          }
        } catch (e, stackTrace) {
          LogService.instance.logError(
            'MediaScannerService: failed to access file for asset $mediaId: $e',
            stackTrace,
          );
        }

        final String folderPath = _extractFolderPath(effectivePath);

        final item = MediaItem(
          id: mediaId,
          path: effectivePath,
          fileName: fileName,
          fileSize: fileSize,
          duration: duration,
          dateAdded: dateAdded,
          dateModified: dateModified,
          width: width,
          height: height,
          isHidden: false,
          folderPath: folderPath,
          thumbnailPath: null,
          videoCodec: null,
          audioCodec: null,
        );

        items.add(item);
      }
    }

    LogService.instance
        .log('MediaScannerService: scanned ${items.length} video items');

    return items;
  }

  /// Returns a mock list of MediaItem objects to simulate a full scan.
  /// Kept for testing and development; not used in normal Day 6 flow.
  Future<List<MediaItem>> performFullScanMock() async {
    final now = DateTime.now();

    final items = <MediaItem>[
      MediaItem(
        id: 'vid_001',
        path: '/storage/emulated/0/Movies/ys_trailer.mp4',
        fileName: 'ys_trailer.mp4',
        fileSize: 150 * 1024 * 1024,
        duration: const Duration(minutes: 2, seconds: 30),
        dateAdded: now.subtract(const Duration(days: 2)),
        dateModified: now.subtract(const Duration(days: 1)),
        width: 1920,
        height: 1080,
        isHidden: false,
        folderPath: '/storage/emulated/0/Movies',
        thumbnailPath: null,
        videoCodec: 'H.264',
        audioCodec: 'AAC',
      ),
      MediaItem(
        id: 'vid_002',
        path: '/storage/emulated/0/Movies/lecture1.mkv',
        fileName: 'lecture1.mkv',
        fileSize: 700 * 1024 * 1024,
        duration: const Duration(hours: 1, minutes: 10),
        dateAdded: now.subtract(const Duration(days: 10)),
        dateModified: now.subtract(const Duration(days: 5)),
        width: 1280,
        height: 720,
        isHidden: false,
        folderPath: '/storage/emulated/0/Movies',
        thumbnailPath: null,
        videoCodec: 'H.265',
        audioCodec: 'AAC',
      ),
      MediaItem(
        id: 'vid_003',
        path:
        '/storage/emulated/0/WhatsApp/Media/Status/video_status_clip.mp4',
        fileName: 'video_status_clip.mp4',
        fileSize: 25 * 1024 * 1024,
        duration: const Duration(seconds: 28),
        dateAdded: now.subtract(const Duration(days: 1)),
        dateModified: now.subtract(const Duration(hours: 12)),
        width: 1080,
        height: 1920,
        isHidden: true,
        folderPath: '/storage/emulated/0/WhatsApp/Media/Status',
        thumbnailPath: null,
        videoCodec: 'H.264',
        audioCodec: 'AAC',
      ),
    ];

    return items;
  }

  /// Computes folder aggregates from a given list of media items.
  /// Groups by [MediaItem.folderPath] and calculates:
  /// - videoCount
  /// - totalSize
  ///
  /// Folder name is derived from the last segment of the folder path.
  List<FolderItem> computeFoldersFromMedia(List<MediaItem> items) {
    final Map<String, _FolderAccum> accum = <String, _FolderAccum>{};

    for (final item in items) {
      final path = item.folderPath;
      final entry = accum.putIfAbsent(path, () => _FolderAccum());
      entry.videoCount++;
      entry.totalSize += item.fileSize;
    }

    final List<FolderItem> folders = <FolderItem>[];

    accum.forEach((folderPath, value) {
      final name = _extractFolderName(folderPath);
      folders.add(
        FolderItem(
          path: folderPath,
          name: name,
          videoCount: value.videoCount,
          totalSize: value.totalSize,
        ),
      );
    });

    return folders;
  }

  /// Temporary mock tags, used until tag management is fully implemented.
  List<TagItem> getMockTags() {
    final now = DateTime.now();
    return <TagItem>[
      TagItem(
        id: 'tag_important',
        name: 'Important',
        colorHex: '#FF6B00',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      TagItem(
        id: 'tag_study',
        name: 'Study',
        colorHex: '#2962FF',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      TagItem(
        id: 'tag_status',
        name: 'Status',
        colorHex: '#00C853',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  String _extractFolderName(String path) {
    if (path.isEmpty) return 'Unknown';
    final parts = path.split('/');
    for (var i = parts.length - 1; i >= 0; i--) {
      final part = parts[i].trim();
      if (part.isNotEmpty) {
        return part;
      }
    }
    return path;
  }

  String _extractFolderPath(String path) {
    if (path.isEmpty) return '/';
    final int idx = path.lastIndexOf('/');
    if (idx <= 0) return '/';
    return path.substring(0, idx);
  }
}

class _FolderAccum {
  int videoCount = 0;
  int totalSize = 0;
}
