import 'dart:async';
import 'package:audio_session/audio_session.dart';

import 'log_service.dart';

/// AudioLifecycleEventType
enum AudioLifecycleEventType {
  becomingNoisy,
  interrupted,
  focusLostTemporary,
  focusLostPermanent,
  focusGained,
}

/// AudioLifecycleEvent
class AudioLifecycleEvent {
  final AudioLifecycleEventType type;
  final String? reason;

  const AudioLifecycleEvent(this.type, {this.reason});
}

/// AudioLifecycleService
class AudioLifecycleService {
  AudioLifecycleService._internal();
  static final AudioLifecycleService instance = AudioLifecycleService._internal();

  final StreamController<AudioLifecycleEvent> _controller =
  StreamController<AudioLifecycleEvent>.broadcast();

  Stream<AudioLifecycleEvent> get events => _controller.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      session.interruptionEventStream.listen((event) {
        LogService.instance.log('Audio interruption: $event');

        switch (event.type) {
          case AudioInterruptionType.duck:
            _controller.add(const AudioLifecycleEvent(
              AudioLifecycleEventType.focusLostTemporary,
            ));
            break;
          case AudioInterruptionType.pause:
            _controller.add(const AudioLifecycleEvent(
              AudioLifecycleEventType.interrupted,
            ));
            break;
          case AudioInterruptionType.unknown:
          // ignore
            break;
        }
      });

      session.becomingNoisyEventStream.listen((_) {
        _controller.add(const AudioLifecycleEvent(
          AudioLifecycleEventType.becomingNoisy,
        ));
      });

      LogService.instance.log('AudioLifecycleService initialized');
    } catch (e, st) {
      LogService.instance.logError(
        'AudioLifecycleService init error: $e',
        st,
      );
    }
  }

  void dispose() {
    _controller.close();
  }
}
