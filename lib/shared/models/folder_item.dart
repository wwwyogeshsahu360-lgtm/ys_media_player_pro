/// FolderItem
/// ==========
/// Immutable model representing a folder that contains one or more videos.
/// Aggregates counts and total size for quick folder-level display.
class FolderItem {
  final String path;
  final String name;
  final int videoCount;
  final int totalSize; // in bytes

  const FolderItem({
    required this.path,
    required this.name,
    required this.videoCount,
    required this.totalSize,
  });

  FolderItem copyWith({
    String? path,
    String? name,
    int? videoCount,
    int? totalSize,
  }) {
    return FolderItem(
      path: path ?? this.path,
      name: name ?? this.name,
      videoCount: videoCount ?? this.videoCount,
      totalSize: totalSize ?? this.totalSize,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'path': path,
      'name': name,
      'videoCount': videoCount,
      'totalSize': totalSize,
    };
  }

  factory FolderItem.fromMap(Map<String, dynamic> map) {
    return FolderItem(
      path: map['path'] as String,
      name: map['name'] as String,
      videoCount: map['videoCount'] as int,
      totalSize: map['totalSize'] as int,
    );
  }

  @override
  String toString() {
    return 'FolderItem('
        'path: $path, '
        'name: $name, '
        'videoCount: $videoCount, '
        'totalSize: $totalSize'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FolderItem) return false;
    return other.path == path &&
        other.name == name &&
        other.videoCount == videoCount &&
        other.totalSize == totalSize;
  }

  @override
  int get hashCode => Object.hash(path, name, videoCount, totalSize);
}
