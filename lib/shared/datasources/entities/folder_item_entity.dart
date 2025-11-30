import 'package:isar/isar.dart';

import '../../models/folder_item.dart';

part 'folder_item_entity.g.dart';

@collection
class FolderItemEntity {
  Id id = Isar.autoIncrement;

  late String path;
  late String name;
  late int videoCount;
  late int totalSize;

  FolderItem toDomain() {
    return FolderItem(
      path: path,
      name: name,
      videoCount: videoCount,
      totalSize: totalSize,
    );
  }

  static FolderItemEntity fromDomain(FolderItem folder) {
    final entity = FolderItemEntity();
    entity.path = folder.path;
    entity.name = folder.name;
    entity.videoCount = folder.videoCount;
    entity.totalSize = folder.totalSize;
    return entity;
  }
}
