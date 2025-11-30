// lib/features/streaming/offline/hls_offline_manager.dart
import '../domain/stream_manifest.dart';
import '../domain/stream_representation.dart';
import '../impl/hls_manifest_parser.dart';
import '../../../shared/services/log_service.dart';

/// Very small stub for HLS offline downloads.
/// Real implementation would use DownloadManager and rewrite manifests.
/// For now it just logs and returns a simple descriptor.
class HlsOfflinePack {
  final String id;
  final Uri manifestUri;
  final StreamRepresentation representation;

  HlsOfflinePack({
    required this.id,
    required this.manifestUri,
    required this.representation,
  });
}

class HlsOfflineManager {
  HlsOfflineManager._internal();

  static final HlsOfflineManager instance = HlsOfflineManager._internal();

  final LogService _log = LogService.instance;

  /// Mock "download" – no real I/O, just logging.
  Future<HlsOfflinePack> downloadPack({
    required Uri manifestUri,
    StreamRepresentation? targetRepresentation,
  }) async {
    _log.log('[HlsOfflineManager] downloadPack called for $manifestUri');

    final StreamManifest manifest =
    await HlsManifestParser.instance.parse(manifestUri);

    final StreamRepresentation rep =
        targetRepresentation ?? manifest.video.first;

    final String id =
        'offline_${manifestUri.toString().hashCode}_${rep.id.hashCode}';

    _log.log(
      '[HlsOfflineManager] (mock) created offline pack id=$id '
          'for representation=${rep.id}',
    );

    return HlsOfflinePack(
      id: id,
      manifestUri: manifestUri,
      representation: rep,
    );
  }

  /// Placeholder: would normally delete downloaded files.
  Future<void> deletePack(HlsOfflinePack pack) async {
    _log.log('[HlsOfflineManager] (mock) deletePack id=${pack.id}');
  }
}
