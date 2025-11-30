import 'player_state.dart';

/// Base type for all player events.
abstract class PlayerEvent {
  const PlayerEvent();
}

/// Periodic position update event.
class PlayerEventPosition extends PlayerEvent {
  const PlayerEventPosition(this.position);

  final Duration position;
}

/// Emitted when high-level state changes, e.g. playing → paused.
class PlayerEventStateChanged extends PlayerEvent {
  const PlayerEventStateChanged(this.state);

  final PlayerState state;
}

/// Emitted when playback hits an error.
class PlayerEventError extends PlayerEvent {
  const PlayerEventError(this.message);

  final String message;
}

/// Emitted when playback reaches the end of current media.
class PlayerEventCompleted extends PlayerEvent {
  const PlayerEventCompleted();
}
