// lib/features/downloads/domain/i_download_storage.dart
import 'dart:io';

abstract class IDownloadStorage {
  /// Base directory where final downloaded files are stored.
  Future<Directory> getBaseDir();

  /// Temp directory (for .part files, etc.).
  Future<Directory> getTempDir();

  /// Resolve final absolute path for given [fileName].
  Future<String> resolveFinalFilePath(String fileName);

  /// Resolve temporary file path for given [id].
  Future<String> resolveTempFilePath(String id);

  /// Optional: check if enough free space is available.
  /// If not supported on platform, can return `null` or a guess.
  Future<int?> getFreeSpaceBytes();
}
