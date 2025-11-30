// lib/features/audio_dsp/impl/mock_native_audio_dsp_engine.dart
import 'dart:async';
import 'dart:math';

import '../domain/audio_dsp_preset.dart';
import '../domain/audio_dsp_state.dart';
import '../domain/i_audio_dsp_engine.dart';
import '../../../shared/services/log_service.dart';

/// Skeleton for a future native / FFmpeg-backed DSP engine.
///
/// Currently this just logs calls and produces a slow, simulated VU meter.
/// Use DartAudioDspEngine as the default; this exists so swapping native
/// implementations later is trivial.
class MockNativeAudioDspEngine implements IAudioDspEngine {
  MockNativeAudioDspEngine();

  static const int _kBandCount = 10;

  final LogService _log = LogService.instance;
  final StreamController<AudioDspState> _stateController =
  StreamController<AudioDspState>.broadcast();

  AudioDspState _state = AudioDspState.initial();
  List<double> _bandGains = List<double>.filled(_kBandCount, 0.0);
  Timer? _timer;
  bool _processing = false;

  @override
  int get bandCount => _kBandCount;

  @override
  List<double> get bandFrequencies => const <double>[
    31,
    62,
    125,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    16000,
  ];

  @override
  List<double> get bandGains => List<double>.from(_bandGains);

  @override
  AudioDspState get lastState => _state;

  @override
  Stream<AudioDspState> get stateStream => _stateController.stream;

  @override
  Future<void> init() async {
    _log.log('[MockNativeAudioDspEngine] init');
  }

  @override
  Future<void> applyPreset(AudioDspPreset preset) async {
    _log.log('[MockNativeAudioDspEngine] applyPreset ${preset.name}');
    if (preset.bandGains.length == _kBandCount) {
      _bandGains = List<double>.from(preset.bandGains);
    }
  }

  @override
  Future<void> setBandGain(int bandIndex, double gainDb) async {
    if (bandIndex < 0 || bandIndex >= _kBandCount) return;
    _bandGains[bandIndex] = gainDb;
  }

  @override
  Future<void> setBassBoost(double amount) async {
    _log.log('[MockNativeAudioDspEngine] setBassBoost($amount)');
  }

  @override
  Future<void> setVirtualizer(double amount) async {
    _log.log('[MockNativeAudioDspEngine] setVirtualizer($amount)');
  }

  @override
  Future<void> setReverb(double amount) async {
    _log.log('[MockNativeAudioDspEngine] setReverb($amount)');
  }

  @override
  Future<void> setLimiterEnabled(bool enabled) async {
    _log.log('[MockNativeAudioDspEngine] setLimiterEnabled($enabled)');
  }

  @override
  Future<void> startProcessing() async {
    if (_processing) return;
    _processing = true;
    final Random rng = Random();
    _timer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      final double v = 0.2 + rng.nextDouble() * 0.6;
      _state = _state.copyWith(
        leftRms: v * 0.7,
        rightRms: v * 0.7,
        leftPeak: v,
        rightPeak: v,
        isProcessing: true,
        timestamp: DateTime.now(),
      );
      if (!_stateController.isClosed) _stateController.add(_state);
    });
  }

  @override
  Future<void> stopProcessing() async {
    _processing = false;
    _timer?.cancel();
    _timer = null;
    _state = _state.copyWith(isProcessing: false);
    if (!_stateController.isClosed) _stateController.add(_state);
  }

  @override
  Future<void> dispose() async {
    _processing = false;
    _timer?.cancel();
    await _stateController.close();
  }
}
