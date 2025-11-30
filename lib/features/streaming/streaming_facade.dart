// lib/features/streaming/streaming_facade.dart
import 'domain/i_adaptive_streamer.dart';
import 'domain/stream_selection_policy.dart';
import 'impl/mock_adaptive_streamer.dart';

/// StreamingFacade
/// ----------------
/// Simple access point for the rest of the app.
/// Currently wires to [MockAdaptiveStreamer] only.
class StreamingFacade {
  StreamingFacade._internal();

  static final StreamingFacade instance = StreamingFacade._internal();

  final IAdaptiveStreamer streamer = MockAdaptiveStreamer.instance;

  final StreamSelectionPolicy defaultPolicy = DefaultStreamSelectionPolicy();
}
