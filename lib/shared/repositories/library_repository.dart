import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../models/tag_item.dart';

/// LibraryRepository
/// =================
/// Abstraction for read operations on the media library, plus explicit
/// rescan operations that force a fresh device scan and persistence.
abstract class LibraryRepository {
  /// Returns all media items, using:
  /// - in-memory cache
  /// - local database
  /// - device scan (fallback when needed)
  Future<List<MediaItem>> getAllMediaItems();

  /// Returns all folder aggregates.
  Future<List<FolderItem>> getAllFolders();

  /// Returns all tags.
  Future<List<TagItem>> getAllTags();

  /// Forces a full rescan from the device, bypassing local cache and
  /// refreshing the persisted media items.
  Future<List<MediaItem>> rescanMediaItems();

  /// Forces a recomputation of folders based on the latest media items
  /// (which may be freshly scanned).
  Future<List<FolderItem>> rescanFolders();
}
