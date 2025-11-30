import 'dart:async';

import '../../../shared/models/media_item.dart';
import 'player_event.dart';
import 'player_state_data.dart';

/// IPlayerBackend
/// ===============
/// Abstraction for the underlying video player engine (ExoPlayer, AVPlayer, etc.).
///
/// Day 10 uses a mock implementation; later we can plug in a real native backend.
abstract class IPlayerBackend {
  /// Initialize underlying engine/resources.
  Future<void> initialize();

  /// Load the given [media] into the player, preparing duration & metadata.
  Future<void> load(MediaItem media);

  /// Start playback (or resume).
  Future<void> play();

  /// Pause playback.
  Future<void> pause();

  /// Stop playback and reset position to zero.
  Future<void> stop();

  /// Seek to a specific [position] within the current media.
  Future<void> seekTo(Duration position);

  /// Change playback speed (e.g. 1.0x, 1.5x, 2.0x).
  Future<void> setSpeed(double speed);

  /// Stream of events emitted by the backend (position updates, state changes, etc.).
  Stream<PlayerEvent> get eventStream;

  /// Get the current state snapshot from the backend.
  Future<PlayerStateData> getCurrentState();

  /// Dispose of any resources and close streams.
  void dispose();
}
