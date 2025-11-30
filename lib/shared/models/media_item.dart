import 'package:flutter/foundation.dart';

/// MediaItem
/// =========
/// Immutable representation of a single video media item discovered on
/// the device. This model is used throughout the app, independent of
/// the underlying database or scanning implementation.
@immutable
class MediaItem {
  final String id;
  final String path;
  final String fileName;
  final int fileSize;
  final Duration duration;
  final DateTime dateAdded;
  final DateTime dateModified;
  final int width;
  final int height;
  final bool isHidden;
  final String folderPath;
  final String? thumbnailPath;
  final String? videoCodec;
  final String? audioCodec;

  const MediaItem({
    required this.id,
    required this.path,
    required this.fileName,
    required this.fileSize,
    required this.duration,
    required this.dateAdded,
    required this.dateModified,
    required this.width,
    required this.height,
    required this.isHidden,
    required this.folderPath,
    this.thumbnailPath,
    this.videoCodec,
    this.audioCodec,
  });

  MediaItem copyWith({
    String? id,
    String? path,
    String? fileName,
    int? fileSize,
    Duration? duration,
    DateTime? dateAdded,
    DateTime? dateModified,
    int? width,
    int? height,
    bool? isHidden,
    String? folderPath,
    String? thumbnailPath,
    String? videoCodec,
    String? audioCodec,
  }) {
    return MediaItem(
      id: id ?? this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      width: width ?? this.width,
      height: height ?? this.height,
      isHidden: isHidden ?? this.isHidden,
      folderPath: folderPath ?? this.folderPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'path': path,
      'fileName': fileName,
      'fileSize': fileSize,
      'durationMs': duration.inMilliseconds,
      'dateAdded': dateAdded.toIso8601String(),
      'dateModified': dateModified.toIso8601String(),
      'width': width,
      'height': height,
      'isHidden': isHidden,
      'folderPath': folderPath,
      'thumbnailPath': thumbnailPath,
      'videoCodec': videoCodec,
      'audioCodec': audioCodec,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    final int durationMs;
    final dynamic rawDuration = map['durationMs'] ?? map['duration'];
    if (rawDuration is int) {
      durationMs = rawDuration;
    } else if (rawDuration is num) {
      durationMs = rawDuration.toInt();
    } else {
      durationMs = 0;
    }

    return MediaItem(
      id: map['id'] as String? ?? '',
      path: map['path'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      fileSize: (map['fileSize'] as int?) ?? 0,
      duration: Duration(milliseconds: durationMs),
      dateAdded: DateTime.tryParse(map['dateAdded'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dateModified: DateTime.tryParse(map['dateModified'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      width: (map['width'] as int?) ?? 0,
      height: (map['height'] as int?) ?? 0,
      isHidden: (map['isHidden'] as bool?) ?? false,
      folderPath: map['folderPath'] as String? ?? '',
      thumbnailPath: map['thumbnailPath'] as String?,
      videoCodec: map['videoCodec'] as String?,
      audioCodec: map['audioCodec'] as String?,
    );
  }

  @override
  String toString() {
    return 'MediaItem(id: $id, fileName: $fileName, path: $path, '
        'fileSize: $fileSize, duration: $duration, '
        'dateAdded: $dateAdded, dateModified: $dateModified, '
        'width: $width, height: $height, isHidden: $isHidden, '
        'folderPath: $folderPath, thumbnailPath: $thumbnailPath, '
        'videoCodec: $videoCodec, audioCodec: $audioCodec)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaItem &&
        other.id == id &&
        other.path == path &&
        other.fileName == fileName &&
        other.fileSize == fileSize &&
        other.duration == duration &&
        other.dateAdded == dateAdded &&
        other.dateModified == dateModified &&
        other.width == width &&
        other.height == height &&
        other.isHidden == isHidden &&
        other.folderPath == folderPath &&
        other.thumbnailPath == thumbnailPath &&
        other.videoCodec == videoCodec &&
        other.audioCodec == audioCodec;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      path,
      fileName,
      fileSize,
      duration,
      dateAdded,
      dateModified,
      width,
      height,
      isHidden,
      folderPath,
      thumbnailPath,
      videoCodec,
      audioCodec,
    );
  }
}
