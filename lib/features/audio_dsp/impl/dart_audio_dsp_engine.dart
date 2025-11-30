// lib/features/audio_dsp/impl/dart_audio_dsp_engine.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import '../domain/audio_dsp_preset.dart';
import '../domain/audio_dsp_state.dart';
import '../domain/i_audio_dsp_engine.dart';
import '../services/audio_dsp_preset_store.dart';
import '../../../shared/services/log_service.dart';

/// A lightweight Dart-only DSP engine.
///
/// NOTE: This does NOT process real PCM from the player yet; instead it
/// simulates meter/spectrum activity based on the current EQ/FX settings
/// in an isolate. The architecture matches what a real engine would use,
/// so you can later swap in proper audio processing.
class DartAudioDspEngine implements IAudioDspEngine {
  DartAudioDspEngine({required AudioDspPresetStore presetStore})
      : _presetStore = presetStore;

  static const int _kBandCount = 10;
  static const List<double> _kFrequencies = <double>[
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

  final AudioDspPresetStore _presetStore;
  final LogService _log = LogService.instance;

  final StreamController<AudioDspState> _stateController =
  StreamController<AudioDspState>.broadcast();

  AudioDspState _lastState = AudioDspState.initial();
  List<double> _bandGains = List<double>.filled(_kBandCount, 0.0);

  double _bassBoost = 0;
  double _virtualizer = 0;
  double _reverb = 0;
  bool _limiterEnabled = false;

  Isolate? _isolate;
  SendPort? _toIsolate;
  StreamSubscription<dynamic>? _isolateSub;

  bool _processing = false;
  AudioDspPreset? _currentPreset;

  @override
  int get bandCount => _kBandCount;

  @override
  List<double> get bandFrequencies => List<double>.from(_kFrequencies);

  @override
  List<double> get bandGains => List<double>.from(_bandGains);

  @override
  AudioDspState get lastState => _lastState;

  @override
  Stream<AudioDspState> get stateStream => _stateController.stream;

  @override
  Future<void> init() async {
    _log.log('[DartAudioDspEngine] init');
    // Prepare initial preset: Flat
    _bandGains = List<double>.filled(_kBandCount, 0.0);
  }

  @override
  Future<void> applyPreset(AudioDspPreset preset) async {
    _log.log('[DartAudioDspEngine] applyPreset ${preset.name}');
    _currentPreset = preset;
    if (preset.bandGains.length == _kBandCount) {
      _bandGains = List<double>.from(preset.bandGains);
    }
    _bassBoost = preset.bassBoost;
    _virtualizer = preset.virtualizer;
    _reverb = preset.reverb;
    _limiterEnabled = preset.limiterEnabled;
    _sendConfigToIsolate();
    _publishState(
      _lastState.copyWith(
        presetId: preset.id,
        presetName: preset.name,
        limiterEnabled: _limiterEnabled,
      ),
    );
  }

  @override
  Future<void> setBandGain(int bandIndex, double gainDb) async {
    if (bandIndex < 0 || bandIndex >= _kBandCount) return;
    _bandGains[bandIndex] = gainDb.clamp(-12.0, 12.0);
    _sendConfigToIsolate();
  }

  @override
  Future<void> setBassBoost(double amount) async {
    _bassBoost = amount.clamp(0.0, 1.0);
    _sendConfigToIsolate();
  }

  @override
  Future<void> setVirtualizer(double amount) async {
    _virtualizer = amount.clamp(0.0, 1.0);
    _sendConfigToIsolate();
  }

  @override
  Future<void> setReverb(double amount) async {
    _reverb = amount.clamp(0.0, 1.0);
    _sendConfigToIsolate();
  }

  @override
  Future<void> setLimiterEnabled(bool enabled) async {
    _limiterEnabled = enabled;
    _sendConfigToIsolate();
  }

  @override
  Future<void> startProcessing() async {
    if (_processing) return;
    _processing = true;
    await _startIsolateIfNeeded();
    _sendConfigToIsolate();
    _sendToIsolate(<String, dynamic>{'type': 'start'});
    _publishState(_lastState.copyWith(isProcessing: true));
  }

  @override
  Future<void> stopProcessing() async {
    if (!_processing) return;
    _processing = false;
    _sendToIsolate(<String, dynamic>{'type': 'stop'});
    _publishState(_lastState.copyWith(isProcessing: false));
  }

  Future<void> _startIsolateIfNeeded() async {
    if (_isolate != null && _toIsolate != null) return;

    final ReceivePort fromIso = ReceivePort();
    _isolate = await Isolate.spawn<_DspIsolateConfig>(
      _dspIsolateEntry,
      _DspIsolateConfig(
        sendPort: fromIso.sendPort,
        bandCount: _kBandCount,
      ),
    );

    _isolateSub = fromIso.listen((dynamic msg) {
      if (msg is SendPort) {
        _toIsolate = msg;
        _sendConfigToIsolate();
      } else if (msg is Map<String, dynamic>) {
        if (msg['type'] == 'state') {
          final AudioDspState state =
          AudioDspState.fromJson(msg['payload'] as Map<String, dynamic>);
          _publishState(state);
        }
      }
    });
  }

  void _sendConfigToIsolate() {
    _sendToIsolate(<String, dynamic>{
      'type': 'config',
      'bandGains': _bandGains,
      'bassBoost': _bassBoost,
      'virtualizer': _virtualizer,
      'reverb': _reverb,
      'limiterEnabled': _limiterEnabled,
      'presetId': _currentPreset?.id,
      'presetName': _currentPreset?.name,
    });
  }

  void _sendToIsolate(Map<String, dynamic> message) {
    final SendPort? port = _toIsolate;
    if (port == null) return;
    port.send(message);
  }

  void _publishState(AudioDspState state) {
    _lastState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  @override
  Future<void> dispose() async {
    _log.log('[DartAudioDspEngine] dispose');
    _processing = false;
    _sendToIsolate(<String, dynamic>{'type': 'dispose'});
    await _isolateSub?.cancel();
    _isolateSub = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    await _stateController.close();
  }
}

/// Data passed once when spawn isolate.
class _DspIsolateConfig {
  final SendPort sendPort;
  final int bandCount;
  const _DspIsolateConfig({
    required this.sendPort,
    required this.bandCount,
  });
}

/// Isolate entry: simulates a DSP engine producing VU + spectrum.
///
/// This is intentionally light-weight and rate-limited (~30 fps).
void _dspIsolateEntry(_DspIsolateConfig config) {
  final ReceivePort fromMain = ReceivePort();
  config.sendPort.send(fromMain.sendPort);

  List<double> bandGains =
  List<double>.filled(config.bandCount, 0.0, growable: false);
  double bassBoost = 0;
  double virtualizer = 0;
  double reverb = 0;
  bool limiterEnabled = false;
  String? presetId;
  String? presetName;

  bool processing = false;
  final Random rng = Random();
  Timer? timer;

  void updateTimer() {
    timer?.cancel();
    if (!processing) return;
    timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final int spectrumBins = 32;
      final List<double> spectrum = List<double>.generate(spectrumBins,
              (int i) {
            final double t = i / spectrumBins;
            // Weighted combination of band gains -> approximate spectral colour.
            final double baseBandIndex = t * (config.bandCount - 1);
            final int i0 = baseBandIndex.floor();
            final int i1 = baseBandIndex.ceil().clamp(0, config.bandCount - 1);
            final double frac = baseBandIndex - i0;
            final double g0 = bandGains[i0];
            final double g1 = bandGains[i1];
            double gain = g0 + (g1 - g0) * frac;

            // Apply bass / virtualizer / reverb as modifiers.
            if (t < 0.25) {
              gain += bassBoost * 6.0;
            }
            gain += virtualizer * (rng.nextDouble() - 0.5) * 2.0;
            gain += reverb * 2.0;

            // Normalize gain to 0..1 for visualization.
            final double norm = ((gain + 12.0) / 24.0).clamp(0.0, 1.0);
            // Add a tiny bit of random motion.
            return (norm + rng.nextDouble() * 0.05).clamp(0.0, 1.0);
          });

      // VU approximated from average spectrum.
      final double avg = spectrum.fold<double>(0, (double a, double b) => a + b) /
          spectrum.length;
      double left = avg + (rng.nextDouble() - 0.5) * 0.1;
      double right = avg + (rng.nextDouble() - 0.5) * 0.1;

      if (limiterEnabled) {
        const double threshold = 0.8;
        if (left > threshold) left = threshold + (left - threshold) * 0.3;
        if (right > threshold) right = threshold + (right - threshold) * 0.3;
      }

      left = left.clamp(0.0, 1.0);
      right = right.clamp(0.0, 1.0);

      final AudioDspState state = AudioDspState(
        leftRms: left * 0.7,
        rightRms: right * 0.7,
        leftPeak: left,
        rightPeak: right,
        spectrum: spectrum,
        presetId: presetId,
        presetName: presetName,
        isProcessing: processing,
        limiterEnabled: limiterEnabled,
        timestamp: DateTime.now(),
      );

      config.sendPort
          .send(<String, dynamic>{'type': 'state', 'payload': state.toJson()});
    });
  }

  fromMain.listen((dynamic message) {
    if (message is Map<String, dynamic>) {
      final String type = message['type'] as String;
      if (type == 'config') {
        final List<dynamic> g = message['bandGains'] as List<dynamic>;
        bandGains =
            g.map((dynamic v) => (v as num).toDouble()).toList(growable: false);
        bassBoost = (message['bassBoost'] as num?)?.toDouble() ?? 0;
        virtualizer = (message['virtualizer'] as num?)?.toDouble() ?? 0;
        reverb = (message['reverb'] as num?)?.toDouble() ?? 0;
        limiterEnabled = message['limiterEnabled'] as bool? ?? false;
        presetId = message['presetId'] as String?;
        presetName = message['presetName'] as String?;
      } else if (type == 'start') {
        processing = true;
        updateTimer();
      } else if (type == 'stop') {
        processing = false;
        updateTimer();
      } else if (type == 'dispose') {
        processing = false;
        timer?.cancel();
        fromMain.close();
      }
    }
  });
}
