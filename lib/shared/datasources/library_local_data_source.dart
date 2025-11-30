import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../models/tag_item.dart';
import '../services/log_service.dart';
import 'entities/media_item_entity.dart';
import 'entities/folder_item_entity.dart';
import 'entities/tag_item_entity.dart';

/// LibraryLocalDataSource
/// ======================
/// Isar-based local persistence layer for the media library.
/// Stores MediaItem and FolderItem (and optionally TagItem) collections.
/// This layer can later be swapped out for another DB by updating only
/// this module and the repository.
class LibraryLocalDataSource {
  LibraryLocalDataSource._internal();

  static final LibraryLocalDataSource instance =
  LibraryLocalDataSource._internal();

  Isar? _isar;

  Future<Isar> _getIsar() async {
    if (_isar != null) {
      return _isar!;
    }

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        MediaItemEntitySchema,
        FolderItemEntitySchema,
        TagItemEntitySchema,
      ],
      directory: dir.path,
    );

    LogService.instance.log(
      'LibraryLocalDataSource: Isar opened at ${dir.path}',
    );

    return _isar!;
  }

  Future<void> saveMediaItems(List<MediaItem> items) async {
    final isar = await _getIsar();

    final entities =
    items.map(MediaItemEntity.fromDomain).toList(growable: false);

    await isar.writeTxn(() async {
      await isar.mediaItemEntitys.clear();
      await isar.mediaItemEntitys.putAll(entities);
    });

    LogService.instance
        .log('LibraryLocalDataSource: saved ${entities.length} media items');
  }

  Future<List<MediaItem>> loadMediaItems() async {
    final isar = await _getIsar();
    final entities = await isar.mediaItemEntitys.where().findAll();
    final result =
    entities.map((entity) => entity.toDomain()).toList(growable: false);

    LogService.instance
        .log('LibraryLocalDataSource: loaded ${result.length} media items');
    return result;
  }

  Future<void> saveFolders(List<FolderItem> items) async {
    final isar = await _getIsar();

    final entities =
    items.map(FolderItemEntity.fromDomain).toList(growable: false);

    await isar.writeTxn(() async {
      await isar.folderItemEntitys.clear();
      await isar.folderItemEntitys.putAll(entities);
    });

    LogService.instance
        .log('LibraryLocalDataSource: saved ${entities.length} folders');
  }

  Future<List<FolderItem>> loadFolders() async {
    final isar = await _getIsar();
    final entities = await isar.folderItemEntitys.where().findAll();
    final result =
    entities.map((entity) => entity.toDomain()).toList(growable: false);

    LogService.instance
        .log('LibraryLocalDataSource: loaded ${result.length} folders');
    return result;
  }

  Future<void> saveTags(List<TagItem> tags) async {
    final isar = await _getIsar();

    final entities =
    tags.map(TagItemEntity.fromDomain).toList(growable: false);

    await isar.writeTxn(() async {
      await isar.tagItemEntitys.clear();
      await isar.tagItemEntitys.putAll(entities);
    });

    LogService.instance
        .log('LibraryLocalDataSource: saved ${entities.length} tags');
  }

  Future<List<TagItem>> loadTags() async {
    final isar = await _getIsar();
    final entities = await isar.tagItemEntitys.where().findAll();
    final result =
    entities.map((entity) => entity.toDomain()).toList(growable: false);

    LogService.instance
        .log('LibraryLocalDataSource: loaded ${result.length} tags');
    return result;
  }
}
