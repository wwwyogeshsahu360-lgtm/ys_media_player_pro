import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../models/tag_item.dart';
import '../services/library_cache_service.dart';
import '../services/log_service.dart';
import '../services/media_scanner_service.dart';
import '../datasources/library_local_data_source.dart';
import 'library_repository.dart';

/// LibraryRepositoryImpl
/// =====================
/// Repository that orchestrates between:
/// - Local persistence (Isar) via LibraryLocalDataSource
/// - Real device scanning via MediaScannerService
/// - In-memory cache via LibraryCacheService
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl()
      : _cacheService = LibraryCacheService.instance,
        _logService = LogService.instance,
        _localDataSource = LibraryLocalDataSource.instance,
        _scannerService = MediaScannerService.instance;

  final LibraryCacheService _cacheService;
  final LogService _logService;
  final LibraryLocalDataSource _localDataSource;
  final MediaScannerService _scannerService;

  @override
  Future<List<MediaItem>> getAllMediaItems() async {
    // 1) Return from in-memory cache if available
    if (_cacheService.mediaItems.isNotEmpty) {
      _logService.log(
        'LibraryRepositoryImpl: returning ${_cacheService.mediaItems.length} media items from cache',
      );
      return _cacheService.mediaItems;
    }

    // 2) Try to load from local DB
    final localItems = await _localDataSource.loadMediaItems();
    if (localItems.isNotEmpty) {
      _logService.log(
        'LibraryRepositoryImpl: loaded ${localItems.length} media items from local database',
      );
      _cacheService.updateCache(mediaItems: localItems);
      return localItems;
    }

    // 3) Fallback to real device scan and persist results
    _logService.log(
      'LibraryRepositoryImpl: local DB empty, performing full device scan',
    );
    final scannedItems = await _scannerService.performFullScan();

    _cacheService.updateCache(mediaItems: scannedItems);
    await _localDataSource.saveMediaItems(scannedItems);

    return scannedItems;
  }

  @override
  Future<List<FolderItem>> getAllFolders() async {
    // 1) Return from in-memory cache if available
    if (_cacheService.folderItems.isNotEmpty) {
      _logService.log(
        'LibraryRepositoryImpl: returning ${_cacheService.folderItems.length} folders from cache',
      );
      return _cacheService.folderItems;
    }

    // 2) Try to load from local DB
    final localFolders = await _localDataSource.loadFolders();
    if (localFolders.isNotEmpty) {
      _logService.log(
        'LibraryRepositoryImpl: loaded ${localFolders.length} folders from local database',
      );
      _cacheService.updateCache(folderItems: localFolders);
      return localFolders;
    }

    // 3) If local folder list is empty, compute from media
    _logService.log(
      'LibraryRepositoryImpl: local DB folders empty, computing from media items',
    );
    final mediaItems = await getAllMediaItems();
    final computedFolders =
    _scannerService.computeFoldersFromMedia(mediaItems);

    _cacheService.updateCache(folderItems: computedFolders);
    await _localDataSource.saveFolders(computedFolders);

    return computedFolders;
  }

  @override
  Future<List<TagItem>> getAllTags() async {
    if (_cacheService.tagItems.isNotEmpty) {
      _logService.log(
        'LibraryRepositoryImpl: returning ${_cacheService.tagItems.length} tags from cache',
      );
      return _cacheService.tagItems;
    }

    // For now, tags are still mock-only.
    final tags = _scannerService.getMockTags();
    _cacheService.updateCache(tagItems: tags);

    _logService.log(
      'LibraryRepositoryImpl: provided ${tags.length} mock tags',
    );

    // Persist tags for later; safe to ignore errors.
    try {
      await _localDataSource.saveTags(tags);
    } catch (e, stackTrace) {
      _logService.logError(
        'LibraryRepositoryImpl: failed to persist tags: $e',
        stackTrace,
      );
    }

    return tags;
  }

  @override
  Future<List<MediaItem>> rescanMediaItems() async {
    _logService.log('LibraryRepositoryImpl: forcing full device rescan');

    final scannedItems = await _scannerService.performFullScan();

    _cacheService.updateCache(mediaItems: scannedItems);
    await _localDataSource.saveMediaItems(scannedItems);

    return scannedItems;
  }

  @override
  Future<List<FolderItem>> rescanFolders() async {
    _logService.log('LibraryRepositoryImpl: recomputing folders from media');

    final mediaItems = _cacheService.mediaItems.isNotEmpty
        ? _cacheService.mediaItems
        : await getAllMediaItems();

    final folders = _scannerService.computeFoldersFromMedia(mediaItems);

    _cacheService.updateCache(folderItems: folders);
    await _localDataSource.saveFolders(folders);

    return folders;
  }
}
