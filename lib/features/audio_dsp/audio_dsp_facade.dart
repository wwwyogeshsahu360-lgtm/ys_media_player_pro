// lib/features/audio_dsp/audio_dsp_facade.dart
import 'package:flutter/foundation.dart';

import 'domain/i_audio_dsp_engine.dart';
import 'impl/dart_audio_dsp_engine.dart';
import 'services/audio_dsp_preset_store.dart';
import 'services/audio_profile_service.dart';

/// Simple facade to provide a singleton DSP engine + related services.
///
/// For now we always use [DartAudioDspEngine]. When you add a real native
/// implementation, you can switch the wiring here.
class AudioDspFacade {
  AudioDspFacade._internal();

  static final AudioDspFacade instance = AudioDspFacade._internal();

  late final IAudioDspEngine engine;
  late final AudioDspPresetStore presetStore;
  late final AudioProfileService profileService;

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    presetStore = AudioDspPresetStore();
    profileService = AudioProfileService();

    // For now choose Dart engine for all builds.
    if (kReleaseMode) {
      engine = DartAudioDspEngine(presetStore: presetStore);
    } else {
      // You could flip this to MockNativeAudioDspEngine for comparative tests.
      engine = DartAudioDspEngine(presetStore: presetStore);
    }

    await engine.init();
    _initialized = true;
  }
}
