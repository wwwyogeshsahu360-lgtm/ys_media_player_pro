import 'package:isar/isar.dart';

import '../../models/media_item.dart';

part 'media_item_entity.g.dart';

@collection
class MediaItemEntity {
  Id id = Isar.autoIncrement;

  late String mediaId;
  late String path;
  late String fileName;
  late int fileSize;
  late int durationMs;
  late DateTime dateAdded;
  late DateTime dateModified;
  late int width;
  late int height;
  late bool isHidden;
  late String folderPath;
  String? thumbnailPath;
  String? videoCodec;
  String? audioCodec;

  MediaItem toDomain() {
    return MediaItem(
      id: mediaId,
      path: path,
      fileName: fileName,
      fileSize: fileSize,
      duration: Duration(milliseconds: durationMs),
      dateAdded: dateAdded,
      dateModified: dateModified,
      width: width,
      height: height,
      isHidden: isHidden,
      folderPath: folderPath,
      thumbnailPath: thumbnailPath,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
    );
  }

  static MediaItemEntity fromDomain(MediaItem item) {
    final entity = MediaItemEntity();
    entity.mediaId = item.id;
    entity.path = item.path;
    entity.fileName = item.fileName;
    entity.fileSize = item.fileSize;
    entity.durationMs = item.duration.inMilliseconds;
    entity.dateAdded = item.dateAdded;
    entity.dateModified = item.dateModified;
    entity.width = item.width;
    entity.height = item.height;
    entity.isHidden = item.isHidden;
    entity.folderPath = item.folderPath;
    entity.thumbnailPath = item.thumbnailPath;
    entity.videoCodec = item.videoCodec;
    entity.audioCodec = item.audioCodec;
    return entity;
  }
}
