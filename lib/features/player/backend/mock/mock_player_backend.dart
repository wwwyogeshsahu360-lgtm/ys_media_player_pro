import 'dart:async';

import '../../../../shared/models/media_item.dart';
import '../i_player_backend.dart';
import '../player_event.dart';
import '../player_state.dart';
import '../player_state_data.dart';

/// MockPlayerBackend
/// =================
/// A mock backend that simulates playback:
/// - fake duration (if media.duration is zero)
/// - play/pause/seek/stop
/// - emits periodic position updates
/// - emits state changes & completion
class MockPlayerBackend implements IPlayerBackend {
  final StreamController<PlayerEvent> _eventController =
  StreamController<PlayerEvent>.broadcast();

  PlayerStateData _state = PlayerStateData.initial();
  Timer? _positionTimer;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    // In a real backend, engine setup would occur here.
    _initialized = true;
  }

  @override
  Future<void> load(MediaItem media) async {
    await initialize();

    _cancelTimer();

    _state = _state.copyWith(
      state: PlayerState.loading,
      position: Duration.zero,
      duration: Duration.zero,
      isBuffering: true,
      errorMessage: null,
      currentMedia: media,
    );
    _emitStateChanged();

    // Simulate async preparation (e.g., fetching metadata).
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final Duration duration =
    media.duration == Duration.zero ? const Duration(minutes: 3) : media.duration;

    _state = _state.copyWith(
      state: PlayerState.ready,
      duration: duration,
      position: Duration.zero,
      isBuffering: false,
    );
    _emitStateChanged();
  }

  @override
  Future<void> play() async {
    if (_state.currentMedia == null) return;
    if (_state.state == PlayerState.playing) return;

    _state = _state.copyWith(
      state: PlayerState.playing,
      isBuffering: false,
    );
    _emitStateChanged();

    _startTimer();
  }

  @override
  Future<void> pause() async {
    if (_state.state != PlayerState.playing) return;
    _cancelTimer();
    _state = _state.copyWith(state: PlayerState.paused);
    _emitStateChanged();
  }

  @override
  Future<void> stop() async {
    _cancelTimer();
    _state = _state.copyWith(
      state: PlayerState.idle,
      position: Duration.zero,
    );
    _emitStateChanged();
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_state.currentMedia == null) return;

    final Duration minPos = Duration.zero;
    final Duration maxPos =
    _state.duration > Duration.zero ? _state.duration : Duration.zero;

    Duration clamped = position;

    if (clamped < minPos) {
      clamped = minPos;
    } else if (maxPos > Duration.zero && clamped > maxPos) {
      clamped = maxPos;
    }

    _state = _state.copyWith(position: clamped);
    _eventController.add(PlayerEventPosition(clamped));
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (speed <= 0) return;
    _state = _state.copyWith(speed: speed);
    _emitStateChanged();
  }

  void _startTimer() {
    _cancelTimer();
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
          (Timer timer) {
        if (_state.state != PlayerState.playing) {
          timer.cancel();
          return;
        }

        final Duration newPos =
            _state.position + const Duration(milliseconds: 500);
        if (newPos >= _state.duration && _state.duration > Duration.zero) {
          // Completed
          _state = _state.copyWith(
            position: _state.duration,
            state: PlayerState.ended,
          );
          _eventController.add(PlayerEventPosition(_state.duration));
          _eventController.add(const PlayerEventCompleted());
          _emitStateChanged();
          timer.cancel();
        } else {
          _state = _state.copyWith(position: newPos);
          _eventController.add(PlayerEventPosition(newPos));
        }
      },
    );
  }

  void _cancelTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _emitStateChanged() {
    _eventController.add(PlayerEventStateChanged(_state.state));
  }

  @override
  Stream<PlayerEvent> get eventStream => _eventController.stream;

  @override
  Future<PlayerStateData> getCurrentState() async => _state;

  @override
  void dispose() {
    _cancelTimer();
    _eventController.close();
  }
}
