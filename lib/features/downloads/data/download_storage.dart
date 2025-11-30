// lib/features/downloads/data/download_storage.dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/i_download_storage.dart';

class DownloadStorage implements IDownloadStorage {
  DownloadStorage._internal();

  static final DownloadStorage instance = DownloadStorage._internal();

  @override
  Future<Directory> getBaseDir() async {
    // App-specific storage for persistent downloads
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory videosDir = Directory('${dir.path}/downloads_videos');
    if (!videosDir.existsSync()) {
      videosDir.createSync(recursive: true);
    }
    return videosDir;
  }

  @override
  Future<Directory> getTempDir() async {
    final Directory dir = await getTemporaryDirectory();
    final Directory tempDir = Directory('${dir.path}/downloads_temp');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    return tempDir;
  }

  @override
  Future<String> resolveFinalFilePath(String fileName) async {
    final Directory base = await getBaseDir();
    return '${base.path}/$fileName';
  }

  @override
  Future<String> resolveTempFilePath(String id) async {
    final Directory temp = await getTempDir();
    return '${temp.path}/$id.part';
  }

  @override
  Future<int?> getFreeSpaceBytes() async {
    // Cross-platform free-space detection is complex;
    // for now return null and let higher layers decide heuristics.
    try {
      final dir = await getBaseDir();
      final stat = await dir.stat();
      // No real free space from FileSystemEntity, this is a placeholder.
      // In future, integrate with platform channel for accurate free space.
      return null;
    } catch (_) {
      return null;
    }
  }
}
