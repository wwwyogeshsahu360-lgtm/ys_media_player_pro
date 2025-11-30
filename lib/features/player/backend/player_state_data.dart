import '../../../shared/models/media_item.dart';
import 'player_state.dart';

/// PlayerStateData
/// ================
/// Immutable snapshot describing the current playback state.
class PlayerStateData {
  const PlayerStateData({
    required this.state,
    required this.position,
    required this.duration,
    required this.isBuffering,
    required this.speed,
    this.errorMessage,
    this.currentMedia,
  });

  /// High-level playback state.
  final PlayerState state;

  /// Current playback position.
  final Duration position;

  /// Known total duration. May be Duration.zero if unknown yet.
  final Duration duration;

  /// Whether the backend is currently buffering data.
  final bool isBuffering;

  /// Playback speed (1.0 = normal, >1.0 = faster).
  final double speed;

  /// Last error message (if in error state).
  final String? errorMessage;

  /// The currently loaded media item, if any.
  final MediaItem? currentMedia;

  PlayerStateData copyWith({
    PlayerState? state,
    Duration? position,
    Duration? duration,
    bool? isBuffering,
    double? speed,
    String? errorMessage,
    MediaItem? currentMedia,
  }) {
    return PlayerStateData(
      state: state ?? this.state,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      speed: speed ?? this.speed,
      errorMessage: errorMessage ?? this.errorMessage,
      currentMedia: currentMedia ?? this.currentMedia,
    );
  }

  /// Initial idle state with no media loaded.
  factory PlayerStateData.initial() {
    return const PlayerStateData(
      state: PlayerState.idle,
      position: Duration.zero,
      duration: Duration.zero,
      isBuffering: false,
      speed: 1.0,
      errorMessage: null,
      currentMedia: null,
    );
  }
}
