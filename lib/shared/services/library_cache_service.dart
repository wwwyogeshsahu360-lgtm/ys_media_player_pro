import 'dart:collection';

import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../models/tag_item.dart';

/// LibraryCacheService
/// ===================
/// In-memory cache of library data. This avoids re-querying the
/// underlying repository or platform for the same data repeatedly.
/// Simple, synchronous access for the rest of the app.
class LibraryCacheService {
  LibraryCacheService._internal();

  static final LibraryCacheService instance = LibraryCacheService._internal();

  List<MediaItem> _mediaItems = const <MediaItem>[];
  List<FolderItem> _folderItems = const <FolderItem>[];
  List<TagItem> _tagItems = const <TagItem>[];

  UnmodifiableListView<MediaItem> get mediaItems =>
      UnmodifiableListView<MediaItem>(_mediaItems);

  UnmodifiableListView<FolderItem> get folderItems =>
      UnmodifiableListView<FolderItem>(_folderItems);

  UnmodifiableListView<TagItem> get tagItems =>
      UnmodifiableListView<TagItem>(_tagItems);

  void updateCache({
    List<MediaItem>? mediaItems,
    List<FolderItem>? folderItems,
    List<TagItem>? tagItems,
  }) {
    if (mediaItems != null) {
      _mediaItems = List<MediaItem>.unmodifiable(mediaItems);
    }
    if (folderItems != null) {
      _folderItems = List<FolderItem>.unmodifiable(folderItems);
    }
    if (tagItems != null) {
      _tagItems = List<TagItem>.unmodifiable(tagItems);
    }
  }

  void clearCache() {
    _mediaItems = const <MediaItem>[];
    _folderItems = const <FolderItem>[];
    _tagItems = const <TagItem>[];
  }
}
