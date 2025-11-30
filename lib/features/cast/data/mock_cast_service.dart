// lib/features/cast/data/mock_cast_service.dart
import 'dart:async';

import '../domain/cast_device.dart';
import '../domain/i_cast_service.dart';
import '../domain/remote_player_state.dart';
import '../../../shared/models/media_item.dart';
import '../../../shared/services/log_service.dart';

/// Mock implementation of [ICastService] used for development & tests.
///
/// It simulates:
/// - discovery of a couple of fake devices
/// - connection / disconnection
/// - playback state changes
class MockCastService implements ICastService {
  MockCastService() {
    _devicesController.add(_fakeDevices);
  }

  final LogService _log = LogService.instance;

  final StreamController<List<CastDevice>> _devicesController =
  StreamController<List<CastDevice>>.broadcast();

  final StreamController<RemotePlayerState> _stateController =
  StreamController<RemotePlayerState>.broadcast();

  CastDevice? _connected;
  RemotePlayerState _state = RemotePlayerState.initial();

  List<CastDevice> get _fakeDevices => const <CastDevice>[
    CastDevice(
      id: 'mock_cast_1',
      name: 'YS Mock Living Room TV',
      ip: '192.168.1.50',
      type: 'mock_cast',
    ),
    CastDevice(
      id: 'mock_cast_2',
      name: 'YS Mock Bedroom TV',
      ip: '192.168.1.51',
      type: 'mock_cast',
    ),
  ];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<List<CastDevice>> discoverDevices() {
    // In a real implementation this would periodically search.
    // Here we just push a fixed list.
    Future<void>.delayed(const Duration(seconds: 1), () {
      _devicesController.add(_fakeDevices);
    });
    return _devicesController.stream;
  }

  @override
  Stream<List<CastDevice>> get devicesStream => _devicesController.stream;

  @override
  Future<void> connectToDevice(CastDevice device) async {
    _connected = device;
    _log.log('[MockCastService] Connected to ${device.name}');
  }

  @override
  Future<void> disconnect() async {
    _log.log('[MockCastService] Disconnected from ${_connected?.name}');
    _connected = null;
    _state = RemotePlayerState.initial();
    _stateController.add(_state);
  }

  @override
  Future<void> playRemote(MediaItem item, {Duration? startAt}) async {
    if (_connected == null) {
      _log.log('[MockCastService] playRemote called without device');
      return;
    }
    _state = RemotePlayerState(
      isPlaying: true,
      position: startAt ?? Duration.zero,
      duration: item.duration,
      mediaId: item.id,
      mediaTitle: item.fileName,
    );
    _stateController.add(_state);
  }

  @override
  Future<void> pauseRemote() async {
    if (_connected == null) return;
    _state = _state.copyWith(isPlaying: false);
    _stateController.add(_state);
  }

  @override
  Future<void> seekRemote(Duration position) async {
    if (_connected == null) return;
    _state = _state.copyWith(position: position);
    _stateController.add(_state);
  }

  @override
  Future<RemotePlayerState> getRemoteState() async => _state;

  @override
  Stream<RemotePlayerState> get stateStream => _stateController.stream;
}
