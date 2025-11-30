// lib/features/audio_dsp/domain/i_audio_dsp_engine.dart
import 'dart:async';

import 'audio_dsp_preset.dart';
import 'audio_dsp_state.dart';

/// Abstract DSP engine interface.
///
/// This is intentionally generic so you can swap a native / FFmpeg / NDK
/// implementation later without touching UI or higher-level services.
abstract class IAudioDspEngine {
  /// Number of EQ bands used by this engine.
  int get bandCount;

  /// Center frequencies for each band (Hz).
  List<double> get bandFrequencies;

  /// Current band gains (dB).
  List<double> get bandGains;

  /// Latest known state.
  AudioDspState get lastState;

  Stream<AudioDspState> get stateStream;

  Future<void> init();

  Future<void> applyPreset(AudioDspPreset preset);

  Future<void> setBandGain(int bandIndex, double gainDb);

  Future<void> setBassBoost(double amount); // 0..1
  Future<void> setVirtualizer(double amount); // 0..1
  Future<void> setReverb(double amount); // 0..1
  Future<void> setLimiterEnabled(bool enabled);

  Future<void> startProcessing();
  Future<void> stopProcessing();

  Future<void> dispose();
}
