// lib/features/downloads/domain/download_status.dart
enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelling,
}

extension DownloadStatusX on DownloadStatus {
  bool get isActive =>
      this == DownloadStatus.queued || this == DownloadStatus.downloading;

  bool get isTerminal =>
      this == DownloadStatus.completed || this == DownloadStatus.failed;

  String get label {
    switch (this) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelling:
        return 'Cancelling';
    }
  }
}
