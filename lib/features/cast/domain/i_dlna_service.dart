// lib/features/cast/domain/i_dlna_service.dart
import 'dart:async';

import 'dlna_device.dart';
import 'remote_player_state.dart';
import '../../../shared/models/media_item.dart';

/// Abstract interface for DLNA / UPnP devices discovered over local network.
abstract class IDlnaService {
  Future<bool> isAvailable();

  Stream<List<DlnaDevice>> discoverDevices();

  Stream<List<DlnaDevice>> get devicesStream;

  Future<void> connectToDevice(DlnaDevice device);

  Future<void> disconnect();

  Future<void> playRemote(MediaItem item, {Duration? startAt});

  Future<void> pauseRemote();

  Future<void> seekRemote(Duration position);

  Future<RemotePlayerState> getRemoteState();

  Stream<RemotePlayerState> get stateStream;
}
