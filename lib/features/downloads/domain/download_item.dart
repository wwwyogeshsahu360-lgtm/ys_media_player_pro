// lib/features/downloads/domain/download_item.dart
import 'dart:convert';

import 'download_status.dart';

class DownloadItem {
  final String id;
  final String url;
  final String? filePath; // final path when completed
  final String? tempFilePath; // temp .part during download
  final int? totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? errorMessage;
  final bool isEncrypted;
  final String? mediaId; // optional link to MediaItem.id

  const DownloadItem({
    required this.id,
    required this.url,
    this.filePath,
    this.tempFilePath,
    this.totalBytes,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.queued,
    this.retryCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.errorMessage,
    this.isEncrypted = false,
    this.mediaId,
  });

  double get progress {
    if (totalBytes == null || totalBytes == 0) return 0.0;
    return downloadedBytes / totalBytes!;
  }

  bool get isCompleted => status == DownloadStatus.completed;

  DownloadItem copyWith({
    String? id,
    String? url,
    String? filePath,
    String? tempFilePath,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    int? retryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? errorMessage,
    bool? isEncrypted,
    String? mediaId,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      tempFilePath: tempFilePath ?? this.tempFilePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      mediaId: mediaId ?? this.mediaId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'url': url,
      'filePath': filePath,
      'tempFilePath': tempFilePath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.index,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'errorMessage': errorMessage,
      'isEncrypted': isEncrypted,
      'mediaId': mediaId,
    };
  }

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'] as String,
      url: map['url'] as String,
      filePath: map['filePath'] as String?,
      tempFilePath: map['tempFilePath'] as String?,
      totalBytes: map['totalBytes'] as int?,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
      status: DownloadStatus.values[map['status'] as int? ?? 0],
      retryCount: map['retryCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      errorMessage: map['errorMessage'] as String?,
      isEncrypted: map['isEncrypted'] as bool? ?? false,
      mediaId: map['mediaId'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory DownloadItem.fromJson(String source) =>
      DownloadItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'DownloadItem(id: $id, url: $url, status: $status, progress: ${progress.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DownloadItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
