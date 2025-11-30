// lib/features/cast/data/mock_dlna_service.dart
import 'dart:async';

import '../domain/dlna_device.dart';
import '../domain/i_dlna_service.dart';
import '../domain/remote_player_state.dart';
import '../../../shared/models/media_item.dart';
import '../../../shared/services/log_service.dart';

/// Mock implementation of [IDlnaService].
///
/// Simulates a couple of DLNA devices and basic playback.
class MockDlnaService implements IDlnaService {
  MockDlnaService() {
    _devicesController.add(_fakeDevices);
  }

  final LogService _log = LogService.instance;

  final StreamController<List<DlnaDevice>> _devicesController =
  StreamController<List<DlnaDevice>>.broadcast();

  final StreamController<RemotePlayerState> _stateController =
  StreamController<RemotePlayerState>.broadcast();

  DlnaDevice? _connected;
  RemotePlayerState _state = RemotePlayerState.initial();

  List<DlnaDevice> get _fakeDevices => <DlnaDevice>[
    DlnaDevice(
      id: 'mock_dlna_1',
      friendlyName: 'YS DLNA Speaker',
      ip: '192.168.1.60',
      controlUrl: Uri.parse('http://192.168.1.60/control'),
    ),
  ];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<List<DlnaDevice>> discoverDevices() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      _devicesController.add(_fakeDevices);
    });
    return _devicesController.stream;
  }

  @override
  Stream<List<DlnaDevice>> get devicesStream => _devicesController.stream;

  @override
  Future<void> connectToDevice(DlnaDevice device) async {
    _connected = device;
    _log.log('[MockDlnaService] Connected to ${device.friendlyName}');
  }

  @override
  Future<void> disconnect() async {
    _log.log('[MockDlnaService] Disconnected from ${_connected?.friendlyName}');
    _connected = null;
    _state = RemotePlayerState.initial();
    _stateController.add(_state);
  }

  @override
  Future<void> playRemote(MediaItem item, {Duration? startAt}) async {
    if (_connected == null) return;
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
