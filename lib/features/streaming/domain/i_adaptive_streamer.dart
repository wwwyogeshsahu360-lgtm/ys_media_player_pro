import 'stream_manifest.dart';
import 'streamer_event.dart';
import 'adaptive_stream_session.dart';
import 'stream_selection_policy.dart';

abstract class IAdaptiveStreamer {
  Stream<StreamerEvent> get events;

  Future<StreamManifest> loadManifest(String url);

  Future<AdaptiveStreamSession> openSession(
      StreamManifest manifest,
      StreamSelectionPolicy policy,
      );

  Future<void> dispose();
}
