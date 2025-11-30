// lib/features/downloads/domain/i_download_manager.dart
import 'download_item.dart';

abstract class IDownloadManager {
  Stream<List<DownloadItem>> get downloadsStream;

  List<DownloadItem> get currentDownloads;

  Future<void> init();

  Future<DownloadItem> enqueueDownload({
    required String url,
    String? mediaId,
    String? suggestedFileName,
    bool isEncrypted = false,
  });

  Future<void> pauseDownload(String id);

  Future<void> resumeDownload(String id);

  Future<void> cancelDownload(String id);

  Future<void> removeDownload(String id);

  DownloadItem? getById(String id);

  DownloadItem? getByUrl(String url);
}
