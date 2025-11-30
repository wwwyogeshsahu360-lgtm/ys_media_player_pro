// lib/features/cast/cast_manager.dart
import 'dart:async';

import 'domain/cast_device.dart';
import 'domain/dlna_device.dart';
import 'domain/i_cast_service.dart';
import 'domain/i_dlna_service.dart';
import 'domain/remote_player_state.dart';
import 'data/mock_cast_service.dart';
import 'data/mock_dlna_service.dart';
import '../../shared/models/media_item.dart';
import '../../shared/services/log_service.dart';

/// Facade that coordinates cast + DLNA services.
///
/// Right now this uses **mock implementations only**, so your app
/// compiles and works without any native plugins.
class CastManager {
  CastManager._internal()
      : _castService = MockCastService(),
        _dlnaService = MockDlnaService() {
    _init();
  }

  static final CastManager instance = CastManager._internal();

  final LogService _log = LogService.instance;

  final ICastService _castService;
  final IDlnaService _dlnaService;

  final StreamController<List<CastDevice>> _allDevicesController =
  StreamController<List<CastDevice>>.broadcast();

  RemotePlayerState _remoteState = RemotePlayerState.initial();
  CastDevice? _currentCastDevice;
  DlnaDevice? _currentDlnaDevice;

  void _init() {
    // Merge cast + dlna device streams into one.
    _castService.discoverDevices().listen((_) {});
    _dlnaService.discoverDevices().listen((_) {});

    _castService.devicesStream.listen((List<CastDevice> castDevices) async {
      final List<DlnaDevice> dlnaDevices =
      await _dlnaService.devicesStream.firstWhere((_) => true,
          orElse: () => <DlnaDevice>[]);
      _emitDevices(castDevices, dlnaDevices);
    });

    _dlnaService.devicesStream.listen((List<DlnaDevice> dlnaDevices) async {
      final List<CastDevice> castDevices =
      await _castService.devicesStream.firstWhere((_) => true,
          orElse: () => <CastDevice>[]);
      _emitDevices(castDevices, dlnaDevices);
    });

    _castService.stateStream.listen((RemotePlayerState state) {
      _remoteState = state;
    });
    _dlnaService.stateStream.listen((RemotePlayerState state) {
      _remoteState = state;
    });
  }

  void _emitDevices(
      List<CastDevice> castDevices,
      List<DlnaDevice> dlnaDevices,
      ) {
    final List<CastDevice> merged = <CastDevice>[
      ...castDevices,
      ...dlnaDevices.map(
            (DlnaDevice d) => CastDevice(
          id: d.id,
          name: d.friendlyName,
          ip: d.ip,
          type: 'dlna_mock',
          supportsVideo: true,
          supportsAudio: true,
        ),
      ),
    ];
    _allDevicesController.add(merged);
  }

  /// Stream of all devices (cast + dlna in a unified view).
  Stream<List<CastDevice>> get devicesStream => _allDevicesController.stream;

  RemotePlayerState get remoteState => _remoteState;

  CastDevice? get connectedDevice => _currentCastDevice;

  Future<void> connectAndPlay(CastDevice device, MediaItem item) async {
    _log.log('[CastManager] connectAndPlay -> ${device.name}');

    if (device.type.startsWith('dlna')) {
      final DlnaDevice dlna = DlnaDevice(
        id: device.id,
        friendlyName: device.name,
        ip: device.ip,
        controlUrl: Uri.parse('http://${device.ip}/control'),
      );
      _currentDlnaDevice = dlna;
      await _dlnaService.connectToDevice(dlna);
      await _dlnaService.playRemote(item, startAt: Duration.zero);
    } else {
      _currentCastDevice = device;
      await _castService.connectToDevice(device);
      await _castService.playRemote(item, startAt: Duration.zero);
    }
  }

  Future<void> pause() async {
    if (_currentDlnaDevice != null) {
      await _dlnaService.pauseRemote();
    } else if (_currentCastDevice != null) {
      await _castService.pauseRemote();
    }
  }

  Future<void> resume() async {
    // For mock we just call playRemote again with same state.
    if (_remoteState.mediaId == null) return;
    final Duration pos = _remoteState.position;
    // In a real implementation we would re-send the media item by id.
    _remoteState = _remoteState.copyWith(isPlaying: true, position: pos);
  }

  Future<void> seek(Duration position) async {
    if (_currentDlnaDevice != null) {
      await _dlnaService.seekRemote(position);
    } else if (_currentCastDevice != null) {
      await _castService.seekRemote(position);
    }
  }

  Future<void> disconnect() async {
    if (_currentDlnaDevice != null) {
      await _dlnaService.disconnect();
      _currentDlnaDevice = null;
    }
    if (_currentCastDevice != null) {
      await _castService.disconnect();
      _currentCastDevice = null;
    }
  }
}
