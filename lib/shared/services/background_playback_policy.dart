import 'log_service.dart';

/// BackgroundPlaybackPolicy
class BackgroundPlaybackPolicy {
  BackgroundPlaybackPolicy._internal();
  static final BackgroundPlaybackPolicy instance = BackgroundPlaybackPolicy._internal();

  bool _enabled = false;

  Future<void> enableBackgroundMode() async {
    _enabled = true;
    LogService.instance.log('[BackgroundPlaybackPolicy] Enabled background mode');
  }

  Future<void> disableBackgroundMode() async {
    _enabled = false;
    LogService.instance.log('[BackgroundPlaybackPolicy] Disabled background mode');
  }

  bool get isEnabled => _enabled;
}
