import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../models/tag_item.dart';
import '../repositories/library_repository.dart';
import '../repositories/library_repository_impl.dart';
import '../services/log_service.dart';
import 'package:ys_media_player_pro/core/errors/media_permission_exception.dart';

/// LibraryController
/// =================
/// ChangeNotifier-based controller responsible for loading and
/// holding the media library state (videos, folders, tags).
///
/// Uses LibraryRepository, which orchestrates between:
/// - Local persistence (Isar)
/// - Real device scanning
/// - In-memory cache
class LibraryController extends ChangeNotifier {
  LibraryController({LibraryRepository? repository})
      : _repository = repository ?? LibraryRepositoryImpl();

  final LibraryRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasPermissionIssue = false;

  List<MediaItem> _videos = const <MediaItem>[];
  List<FolderItem> _folders = const <FolderItem>[];
  List<TagItem> _tags = const <TagItem>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPermissionIssue => _hasPermissionIssue;

  UnmodifiableListView<MediaItem> get videos =>
      UnmodifiableListView<MediaItem>(_videos);

  UnmodifiableListView<FolderItem> get folders =>
      UnmodifiableListView<FolderItem>(_folders);

  UnmodifiableListView<TagItem> get tags =>
      UnmodifiableListView<TagItem>(_tags);

  bool get hasLoadedAnyData =>
      _videos.isNotEmpty || _folders.isNotEmpty || _tags.isNotEmpty;

  /// Refreshes the library data (videos, folders, tags) using the
  /// normal repository flow:
  /// - cache
  /// - local database
  /// - device scan when needed
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    _hasPermissionIssue = false;
    notifyListeners();

    try {
      final videos = await _repository.getAllMediaItems();
      final folders = await _repository.getAllFolders();
      final tags = await _repository.getAllTags();

      _videos = List<MediaItem>.unmodifiable(videos);
      _folders = List<FolderItem>.unmodifiable(folders);
      _tags = List<TagItem>.unmodifiable(tags);

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _isLoading = false;

      if (e is MediaPermissionException) {
        _hasPermissionIssue = true;
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Failed to load media library.';
      }

      LogService.instance
          .logError('LibraryController.refresh error: $e', stackTrace);
      notifyListeners();
    }
  }

  /// Forces a real device rescan, bypassing cache/local-only flows
  /// where necessary.
  Future<void> refreshFromDevice() async {
    _isLoading = true;
    _errorMessage = null;
    _hasPermissionIssue = false;
    notifyListeners();

    try {
      final videos = await _repository.rescanMediaItems();
      final folders = await _repository.rescanFolders();
      final tags = await _repository.getAllTags();

      _videos = List<MediaItem>.unmodifiable(videos);
      _folders = List<FolderItem>.unmodifiable(folders);
      _tags = List<TagItem>.unmodifiable(tags);

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _isLoading = false;

      if (e is MediaPermissionException) {
        _hasPermissionIssue = true;
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Failed to scan media library from device.';
      }

      LogService.instance.logError(
        'LibraryController.refreshFromDevice error: $e',
        stackTrace,
      );
      notifyListeners();
    }
  }

  void clear() {
    _videos = const <MediaItem>[];
    _folders = const <FolderItem>[];
    _tags = const <TagItem>[];
    _errorMessage = null;
    _hasPermissionIssue = false;
    _isLoading = false;
    notifyListeners();
  }
}
