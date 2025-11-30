import 'package:isar/isar.dart';
import '../../models/tag_item.dart';

part 'tag_item_entity.g.dart';

@collection
class TagItemEntity {
  Id id = Isar.autoIncrement;

  late String tagId;
  late String name;
  late String colorHex;
  late DateTime createdAt;

  TagItem toDomain() {
    return TagItem(
      id: tagId,
      name: name,
      colorHex: colorHex,
      createdAt: createdAt,
    );
  }

  static TagItemEntity fromDomain(TagItem tag) {
    final entity = TagItemEntity();
    entity.tagId = tag.id;
    entity.name = tag.name;
    entity.colorHex = tag.colorHex;
    entity.createdAt = tag.createdAt;
    return entity;
  }
}
