// lib/features/cast/domain/i_cast_service.dart
import 'dart:async';

import 'cast_device.dart';
import 'remote_player_state.dart';
import '../../../shared/models/media_item.dart';

/// Abstract interface for "cast-like" targets (Chromecast, Smart TV, etc.).
abstract class ICastService {
  /// Whether cast is supported/available on this platform.
  Future<bool> isAvailable();

  /// Discover devices continuously.
  ///
  /// Implementations may reuse the same stream instance.
  Stream<List<CastDevice>> discoverDevices();

  /// The stream of latest discovered devices.
  Stream<List<CastDevice>> get devicesStream;

  /// Connect to a device.
  Future<void> connectToDevice(CastDevice device);

  /// Disconnect from current device (if any).
  Future<void> disconnect();

  /// Start remote playback of [item].
  Future<void> playRemote(MediaItem item, {Duration? startAt});

  Future<void> pauseRemote();

  Future<void> seekRemote(Duration position);

  /// Current remote player state, polled or pushed.
  Future<RemotePlayerState> getRemoteState();

  /// Stream of player state updates.
  Stream<RemotePlayerState> get stateStream;
}
