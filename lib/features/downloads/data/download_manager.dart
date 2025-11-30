// lib/features/downloads/data/download_manager.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/media_item.dart';
import '../../../shared/services/log_service.dart';
import '../../../shared/telemetry/telemetry_service.dart';
import '../domain/download_item.dart';
import '../domain/download_status.dart';
import '../domain/i_download_manager.dart';
import 'download_storage.dart';

const String _kDownloadsPrefsKey = 'ys_download_items_v1';

class DownloadManager implements IDownloadManager {
  DownloadManager._internal();

  static final DownloadManager instance = DownloadManager._internal();

  final Dio _dio = Dio();

  /// All downloads held in memory, keyed by [DownloadItem.id].
  final Map<String, DownloadItem> _items = <String, DownloadItem>{};

  /// Active cancel tokens for running downloads.
  final Map<String, CancelToken> _tokens = <String, CancelToken>{};

  /// Broadcast stream for UI listeners (DownloadsTab etc.).
  final StreamController<List<DownloadItem>> _downloadsController =
  StreamController<List<DownloadItem>>.broadcast();

  bool _initialized = false;

  /// Maximum concurrent downloads.
  int _maxConcurrent = 2;

  /// Currently active downloads.
  int _activeCount = 0;

  /// True while queue loop is running.
  bool _processing = false;

  // =========================================================
  // Public Read API
  // =========================================================

  @override
  Stream<List<DownloadItem>> get downloadsStream =>
      _downloadsController.stream;

  @override
  List<DownloadItem> get currentDownloads =>
      _items.values.toList()
        ..sort((DownloadItem a, DownloadItem b) =>
            a.createdAt.compareTo(b.createdAt));

  // =========================================================
  // Init
  // =========================================================

  @override
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _loadFromPrefs();
    _emit();

    // Reset any "in-progress" states to paused on startup.
    _items.updateAll((String key, DownloadItem value) {
      if (value.status == DownloadStatus.downloading ||
          value.status == DownloadStatus.cancelling) {
        return value.copyWith(status: DownloadStatus.paused);
      }
      return value;
    });
    _emit();
    _scheduleProcessQueue();

    LogService.instance.log(
      '[DownloadManager] initialized with ${_items.length} items',
    );
  }

  // =========================================================
  // Enqueue / Control
  // =========================================================

  /// Enqueue a download for a raw [url].
  @override
  Future<DownloadItem> enqueueDownload({
    required String url,
    String? mediaId,
    String? suggestedFileName,
    bool isEncrypted = false,
  }) async {
    await init();

    // If same URL already in list, just return it.
    final DownloadItem? existing = getByUrl(url);
    if (existing != null) {
      LogService.instance.log(
        '[DownloadManager] enqueueDownload: already exists, id=${existing.id}',
      );
      return existing;
    }

    final String id = _buildIdFromUrl(url);

    final DateTime now = DateTime.now();
    String fileName;
    if (suggestedFileName != null && suggestedFileName.trim().isNotEmpty) {
      fileName = suggestedFileName;
    } else {
      final Uri? uri = Uri.tryParse(url);
      fileName = uri?.pathSegments.isNotEmpty == true
          ? uri!.pathSegments.last
          : 'video_$id.mp4';
    }

    final String finalPath =
    await DownloadStorage.instance.resolveFinalFilePath(fileName);
    final String tempPath =
    await DownloadStorage.instance.resolveTempFilePath(id);

    final DownloadItem item = DownloadItem(
      id: id,
      url: url,
      filePath: finalPath,
      tempFilePath: tempPath,
      totalBytes: null,
      downloadedBytes: 0,
      status: DownloadStatus.queued,
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
      errorMessage: null,
      isEncrypted: isEncrypted,
      mediaId: mediaId,
    );

    _items[id] = item;
    _emit();
    await _saveToPrefs();
    _scheduleProcessQueue();

    LogService.instance.log('[DownloadManager] Enqueued download: $item');

    // Telemetry: download_started
    TelemetryService.instance.trackEvent(
      'download_started',
      <String, dynamic>{
        'id': id,
        'url': url,
        'mediaId': mediaId,
        'fileName': fileName,
      },
    );

    return item;
  }

  /// Convenience: Enqueue a download directly from a [MediaItem].
  Future<DownloadItem> enqueueFromMediaItem(MediaItem media) {
    return enqueueDownload(
      url: media.path,
      mediaId: media.id,
      suggestedFileName: media.fileName,
    );
  }

  @override
  Future<void> pauseDownload(String id) async {
    final DownloadItem? item = _items[id];
    if (item == null) return;

    LogService.instance.log('[DownloadManager] pauseDownload: $id');

    _tokens[id]?.cancel('paused');
    _tokens.remove(id);

    _updateItem(
      id,
      item.copyWith(
        status: DownloadStatus.paused,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> resumeDownload(String id) async {
    final DownloadItem? item = _items[id];
    if (item == null) return;

    LogService.instance.log('[DownloadManager] resumeDownload: $id');

    if (item.status == DownloadStatus.paused ||
        item.status == DownloadStatus.failed) {
      _updateItem(
        id,
        item.copyWith(
          status: DownloadStatus.queued,
          updatedAt: DateTime.now(),
        ),
      );
      _scheduleProcessQueue();
    }
  }

  /// Retry a failed download from scratch, resetting progress but keeping metadata.
  Future<void> retryDownload(String id) async {
    final DownloadItem? item = _items[id];
    if (item == null) return;

    LogService.instance.log('[DownloadManager] retryDownload: $id');

    final DownloadItem reset = item.copyWith(
      status: DownloadStatus.queued,
      downloadedBytes: 0,
      retryCount: 0,
      errorMessage: null,
      updatedAt: DateTime.now(),
    );

    _items[id] = reset;
    _emit();
    await _saveToPrefs();
    _scheduleProcessQueue();
  }

  @override
  Future<void> cancelDownload(String id) async {
    final DownloadItem? item = _items[id];
    if (item == null) return;

    LogService.instance.log('[DownloadManager] cancelDownload: $id');

    _updateItem(
      id,
      item.copyWith(
        status: DownloadStatus.cancelling,
        updatedAt: DateTime.now(),
      ),
    );

    _tokens[id]?.cancel('cancelled');
    _tokens.remove(id);

    try {
      if (item.tempFilePath != null) {
        final File f = File(item.tempFilePath!);
        if (f.existsSync()) {
          await f.delete();
        }
      }
    } catch (e, st) {
      LogService.instance.logError(
        '[DownloadManager] cancelDownload delete temp failed: $e',
        st,
      );
    }

    _items.remove(id);
    _emit();
    await _saveToPrefs();
  }

  @override
  Future<void> removeDownload(String id) async {
    final DownloadItem? item = _items[id];
    if (item == null) return;

    LogService.instance.log('[DownloadManager] removeDownload: $id');

    _tokens[id]?.cancel('remove');
    _tokens.remove(id);

    try {
      if (item.filePath != null) {
        final File f = File(item.filePath!);
        if (f.existsSync()) {
          await f.delete();
        }
      }
    } catch (e, st) {
      LogService.instance.logError(
        '[DownloadManager] removeDownload delete failed: $e',
        st,
      );
    }

    _items.remove(id);
    _emit();
    await _saveToPrefs();
  }

  @override
  DownloadItem? getById(String id) => _items[id];

  @override
  DownloadItem? getByUrl(String url) {
    for (final DownloadItem item in _items.values) {
      if (item.url == url) return item;
    }
    return null;
  }

  /// Get DownloadItem associated with a [MediaItem] (by mediaId or URL/path).
  DownloadItem? getDownloadForMedia(MediaItem media) {
    for (final DownloadItem item in _items.values) {
      if (item.mediaId == media.id || item.url == media.path) {
        return item;
      }
    }
    return null;
  }

  // =========================================================
  // Queue Processing
  // =========================================================

  void _scheduleProcessQueue() {
    if (_processing) return;
    _processing = true;
    Future<void>.microtask(_processQueue);
  }

  Future<void> _processQueue() async {
    try {
      while (true) {
        if (_activeCount >= _maxConcurrent) break;

        DownloadItem? next;
        for (final DownloadItem item in _items.values) {
          if (item.status == DownloadStatus.queued) {
            next = item;
            break;
          }
        }
        if (next == null) break;

        _activeCount++;
        _startDownload(next).whenComplete(() {
          _activeCount = max(0, _activeCount - 1);
          _scheduleProcessQueue();
        });
      }
    } catch (e, st) {
      LogService.instance
          .logError('[DownloadManager] _processQueue error: $e', st);
    } finally {
      _processing = false;
    }
  }

  Future<void> _startDownload(DownloadItem item) async {
    final String id = item.id;
    final String url = item.url;

    LogService.instance.log('[DownloadManager] startDownload: $id ($url)');

    final CancelToken cancelToken = CancelToken();
    _tokens[id] = cancelToken;

    _updateItem(
      id,
      item.copyWith(
        status: DownloadStatus.downloading,
        updatedAt: DateTime.now(),
        errorMessage: null,
      ),
    );

    int downloaded = item.downloadedBytes;
    int? total = item.totalBytes;

    try {
      final String tempPath = item.tempFilePath!;
      final File tempFile = File(tempPath);

      if (!tempFile.existsSync()) {
        tempFile.createSync(recursive: true);
        downloaded = 0;
      } else {
        downloaded = await tempFile.length();
      }

      final RandomAccessFile raf =
      tempFile.openSync(mode: FileMode.append);

      final Map<String, dynamic> headers = <String, dynamic>{};
      if (downloaded > 0) {
        headers['Range'] = 'bytes=$downloaded-';
      }

      final Response<ResponseBody> response =
      await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      final String? contentLengthHeader =
      response.headers.value(HttpHeaders.contentLengthHeader);

      if (contentLengthHeader != null) {
        final int? newContent = int.tryParse(contentLengthHeader);
        if (newContent != null) {
          total = downloaded + newContent;
        }
      }

      final Stream<List<int>> stream = response.data!.stream;

      await for (final List<int> chunk in stream) {
        if (cancelToken.isCancelled) {
          LogService.instance.log(
            '[DownloadManager] download cancelled mid-stream: $id',
          );
          break;
        }

        raf.writeFromSync(chunk);
        downloaded += chunk.length;

        final DownloadItem? current = _items[id];
        if (current == null) continue;

        _updateItem(
          id,
          current.copyWith(
            downloadedBytes: downloaded,
            totalBytes: total ?? current.totalBytes,
            updatedAt: DateTime.now(),
          ),
        );

        // Telemetry: sampled progress (not every chunk, but ok for now).
        TelemetryService.instance.trackEvent(
          'download_progress',
          <String, dynamic>{
            'id': id,
            'url': url,
            'downloaded': downloaded,
            'total': total,
          },
          sampling: 0.05, // 5% sampling to avoid too many events.
        );
      }

      await raf.close();

      if (cancelToken.isCancelled) {
        return;
      }

      // Atomic completion: rename temp to final file path
      if (item.filePath != null) {
        final File finalFile = File(item.filePath!);
        try {
          if (finalFile.existsSync()) {
            await finalFile.delete();
          }
          await tempFile.rename(item.filePath!);
        } catch (e, st) {
          LogService.instance.logError(
            '[DownloadManager] rename temp->final failed: $e',
            st,
          );
        }
      }

      final DownloadItem? completed = _items[id];
      if (completed != null) {
        _updateItem(
          id,
          completed.copyWith(
            status: DownloadStatus.completed,
            downloadedBytes: downloaded,
            totalBytes: total ?? completed.totalBytes ?? downloaded,
            updatedAt: DateTime.now(),
          ),
        );
      }

      LogService.instance.log('[DownloadManager] download completed: $id');

      TelemetryService.instance.trackEvent(
        'download_completed',
        <String, dynamic>{
          'id': id,
          'url': url,
          'downloaded': downloaded,
          'total': total,
        },
      );
    } catch (e, st) {
      if (e is DioException && CancelToken.isCancel(e)) {
        LogService.instance
            .log('[DownloadManager] download cancelled token: $id');
        return;
      }

      LogService.instance
          .logError('[DownloadManager] download error for $id: $e', st);

      TelemetryService.instance.trackEvent(
        'download_failed',
        <String, dynamic>{
          'id': id,
          'url': url,
          'error': e.toString(),
        },
      );

      final DownloadItem? current = _items[id];
      if (current != null) {
        final int newRetry = current.retryCount + 1;
        const int maxRetries = 3;

        if (newRetry <= maxRetries) {
          final int backoffSec = pow(2, newRetry).toInt();
          _updateItem(
            id,
            current.copyWith(
              status: DownloadStatus.queued,
              retryCount: newRetry,
              updatedAt: DateTime.now(),
              errorMessage: e.toString(),
            ),
          );
          _emit();
          await _saveToPrefs();

          LogService.instance.log(
            '[DownloadManager] scheduling retry in ${backoffSec}s for $id',
          );

          await Future<void>.delayed(Duration(seconds: backoffSec));
          _scheduleProcessQueue();
        } else {
          _updateItem(
            id,
            current.copyWith(
              status: DownloadStatus.failed,
              updatedAt: DateTime.now(),
              errorMessage: e.toString(),
            ),
          );
          _emit();
          await _saveToPrefs();
        }
      }
    } finally {
      _tokens.remove(id);
      await _saveToPrefs();
    }
  }

  // =========================================================
  // Helpers: state + persistence
  // =========================================================

  void _updateItem(String id, DownloadItem newItem) {
    _items[id] = newItem;
    _emit();
  }

  void _emit() {
    if (!_downloadsController.isClosed) {
      _downloadsController.add(currentDownloads);
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();
      final List<String> list =
      _items.values.map((DownloadItem e) => e.toJson()).toList();
      await prefs.setStringList(_kDownloadsPrefsKey, list);
    } catch (e, st) {
      LogService.instance
          .logError('[DownloadManager] saveToPrefs error: $e', st);
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();
      final List<String>? list =
      prefs.getStringList(_kDownloadsPrefsKey);
      if (list == null) return;

      for (final String jsonStr in list) {
        try {
          final DownloadItem item = DownloadItem.fromJson(jsonStr);
          _items[item.id] = item;
        } catch (_) {
          // ignore individual corrupt items
        }
      }
    } catch (e, st) {
      LogService.instance
          .logError('[DownloadManager] loadFromPrefs error: $e', st);
    }
  }

  // =========================================================
  // ID helper
  // =========================================================

  /// Build a relatively unique ID based on URL + timestamp.
  String _buildIdFromUrl(String url) {
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final int rnd = Random().nextInt(9999);
    final String base = url.hashCode.toRadixString(16);
    return '${base}_$ts\_$rnd';
  }
}
