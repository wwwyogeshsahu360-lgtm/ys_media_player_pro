import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'log_service.dart';
import '../../features/player/backend/player_state.dart';
import '../../features/player/backend/player_state_data.dart';
import '../models/media_item.dart';

class NotificationController {
  NotificationController._internal();
  static final NotificationController instance = NotificationController._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const init = InitializationSettings(android: android);

      await _plugin.initialize(init);

      LogService.instance.log('[NotificationController] Initialized');
    } catch (e, st) {
      LogService.instance.logError(
        '[NotificationController] init error: $e',
        st,
      );
    }
  }

  Future<void> showPlaybackNotification(
      MediaItem media, PlayerStateData state) async {
    try {
      await init();

      final androidDetails = AndroidNotificationDetails(
        'ys_player_channel',
        'YS Player Playback',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: state.state == PlayerState.playing,
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        100,
        media.fileName,
        'Playing • ${state.position.inMinutes}:${(state.position.inSeconds % 60).toString().padLeft(2, "0")}',
        details,
      );

      LogService.instance.log('[NotificationController] showPlaybackNotification');
    } catch (e, st) {
      LogService.instance.logError(
        '[NotificationController] showPlaybackNotification error: $e',
        st,
      );
    }
  }

  Future<void> updatePlaybackNotification(PlayerStateData state) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'ys_player_channel',
        'YS Player Playback',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: state.state == PlayerState.playing,
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        100,
        state.currentMedia?.fileName ?? 'Playback',
        state.state == PlayerState.paused
            ? 'Paused'
            : 'Playing • ${state.position.inMinutes}:${(state.position.inSeconds % 60).toString().padLeft(2, "0")}',
        details,
      );
    } catch (e, st) {
      LogService.instance.logError(
        '[NotificationController] update error: $e',
        st,
      );
    }
  }

  Future<void> hidePlaybackNotification() async {
    try {
      await _plugin.cancel(100);
      LogService.instance.log('[NotificationController] hidePlaybackNotification');
    } catch (e, st) {
      LogService.instance.logError(
        '[NotificationController] hide error: $e',
        st,
      );
    }
  }
}
