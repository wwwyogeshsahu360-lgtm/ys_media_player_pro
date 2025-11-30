// lib/features/streaming/impl/mock_adaptive_streamer.dart
import 'dart:async';

import '../domain/i_adaptive_streamer.dart';
import '../domain/stream_manifest.dart';
import '../domain/stream_representation.dart';
import '../domain/stream_selection_policy.dart';
import '../domain/streamer_event.dart';
import '../domain/adaptive_stream_session.dart';
import '../domain/drm/drm_models.dart';
import 'hls_manifest_parser.dart';
import 'dash_manifest_parser.dart';
import '../../../shared/services/log_service.dart';

/// MockAdaptiveStreamer
/// --------------------
/// Pure Dart, no real networking. It creates fake manifests and sessions
/// so the rest of the app / debug UI can work without native streaming plugins.
class MockAdaptiveStreamer implements IAdaptiveStreamer {
  MockAdaptiveStreamer._internal();

  static final MockAdaptiveStreamer instance = MockAdaptiveStreamer._internal();

  final StreamController<StreamerEvent> _events =
  StreamController<StreamerEvent>.broadcast();

  final LogService _log = LogService.instance;

  @override
  Stream<StreamerEvent> get events => _events.stream;

  bool _disposed = false;

  @override
  Future<StreamManifest> loadManifest(String url) async {
    if (_disposed) {
      throw StateError('MockAdaptiveStreamer is disposed');
    }

    final Uri uri = Uri.parse(url);
    StreamManifest manifest;

    if (url.endsWith('.m3u8')) {
      manifest = await HlsManifestParser.instance.parse(uri);
    } else if (url.endsWith('.mpd')) {
      manifest = await DashManifestParser.instance.parse(uri);
    } else {
      // Fallback: just treat as HLS-like
      manifest = await HlsManifestParser.instance.parse(uri);
    }

    _events.add(ManifestLoadedEvent());
    _log.log('[MockAdaptiveStreamer] Manifest loaded for $url '
        '(type=${manifest.type})');

    // If DRM signals exist but we are in mock mode, just log a warning.
    for (final DrmSignal drm in manifest.drmSignals) {
      _log.log(
        '[MockAdaptiveStreamer] DRM signal detected (scheme=${drm.scheme}) '
            'but no native DRM integration is wired. Running in mock mode.',
      );
    }

    return manifest;
  }

  @override
  Future<AdaptiveStreamSession> openSession(
      StreamManifest manifest,
      StreamSelectionPolicy policy,
      ) async {
    if (_disposed) {
      throw StateError('MockAdaptiveStreamer is disposed');
    }

    if (manifest.video.isEmpty) {
      throw StateError('Manifest has no video representations');
    }

    // Pretend we have decent bandwidth (5 Mbps)
    const int estimatedBandwidth = 5 * 1000 * 1000;

    final StreamRepresentation chosen =
    policy.selectBestRepresentation(manifest.video, estimatedBandwidth);

    final AdaptiveStreamSession session = AdaptiveStreamSession(
      currentRepresentation: chosen,
      downloadedBytes: 0,
      position: Duration.zero,
    );

    _events.add(SessionOpenedEvent(session));
    _events.add(RepresentationChangedEvent(chosen));
    _events.add(BandwidthUpdatedEvent(estimatedBandwidth));

    _log.log(
      '[MockAdaptiveStreamer] Session opened with representation=${chosen.id} '
          '(${chosen.width}x${chosen.height} @ ${chosen.bandwidth} bps)',
    );

    // Simulate segment downloads via periodic fake events.
    _simulateSegmentLoop(chosen);

    return session;
  }

  void _simulateSegmentLoop(StreamRepresentation repr) {
    // 5 fake segments of 2s each.
    const int segmentCount = 5;
    const Duration segmentDuration = Duration(seconds: 2);

    for (int i = 0; i < segmentCount; i++) {
      Future<void>.delayed(segmentDuration * (i + 1), () {
        if (_disposed) return;
        const int bytes = 200 * 1024; // ~200 KB per segment
        _events.add(SegmentDownloadedEvent(bytes));
      });
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _events.close();
  }
}
