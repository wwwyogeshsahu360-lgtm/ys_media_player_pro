import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../shared/models/media_item.dart';
import '../../../shared/services/audio_lifecycle_service.dart';
import '../../../shared/services/background_playback_policy.dart';
import '../../../shared/services/notification_controller.dart';
import '../../../shared/services/log_service.dart';
import '../../downloads/data/download_manager.dart';
import '../../downloads/domain/download_status.dart';

import '../../subtitles/models/subtitle_cue.dart';
import '../../subtitles/models/subtitle_track.dart';
import '../../subtitles/services/subtitle_service.dart';
import '../../subtitles/services/subtitle_session_repository.dart';

import '../backend/i_player_backend.dart';
import '../backend/mock/mock_player_backend.dart';
import '../backend/player_event.dart';
import '../backend/player_state.dart';
import '../backend/player_state_data.dart';

/// PlayerController (Day 1–13 + Day 14 Offline Integration)
class PlayerController extends ChangeNotifier {
  PlayerController({ IPlayerBackend? backend })
      : _backend = backend ?? MockPlayerBackend() {
    _state = PlayerStateData.initial();
    _init();
  }

  final IPlayerBackend _backend;

  late PlayerStateData _state;
  PlayerStateData get state => _state;

  StreamSubscription<PlayerEvent>? _backendSub;
  StreamSubscription<AudioLifecycleEvent>? _audioLifecycleSub;

  bool _disposed = false;

  String? _externalPauseMessage;
  String? get externalPauseMessage => _externalPauseMessage;

  void Function(AudioLifecycleEvent event)? onLifecycleEvent;

  // -----------------------------
  // Subtitle state (Day 13)
  // -----------------------------
  List<SubtitleTrack> _subtitleTracks = <SubtitleTrack>[];
  SubtitleTrack? _currentSubtitleTrack;
  Duration _subtitleOffset = Duration.zero;

  List<SubtitleTrack> get subtitleTracks => List.unmodifiable(_subtitleTracks);
  SubtitleTrack? get currentSubtitleTrack => _currentSubtitleTrack;
  Duration get subtitleOffset => _subtitleOffset;

  List<SubtitleCue> get currentSubtitleCues =>
      _currentSubtitleTrack?.cues ?? const <SubtitleCue>[];

  // =====================================================
  // INITIALIZE
  // =====================================================
  Future<void> _init() async {
    await AudioLifecycleService.instance.init();

    _backendSub = _backend.eventStream.listen(_onBackendEvent);
    _audioLifecycleSub =
        AudioLifecycleService.instance.events.listen(_onAudioLifecycleEvent);

    LogService.instance.log('[PlayerController] initialized');
  }

  // =====================================================
  // DAY-14 OFFLINE MEDIA RESOLUTION
  // =====================================================
  Future<MediaItem> _resolveOfflineMedia(MediaItem media) async {
    final download =
    DownloadManager.instance.getByUrl(media.path);

    if (download != null &&
        download.status == DownloadStatus.completed &&
        download.filePath != null) {
      try {
        final offline = media.copyWith(path: download.filePath!);
        LogService.instance.log(
            '[PlayerController] Using offline file: ${offline.path}');
        return offline;
      } catch (e) {
        LogService.instance.log(
            '[PlayerController] Failed to apply offline media: $e');
      }
    }

    return media;
  }

  // =====================================================
  // PUBLIC API
  // =====================================================
  Future<void> load(MediaItem media) async {
    LogService.instance.log('[PlayerController] load: ${media.fileName}');
    _externalPauseMessage = null;

    // NEW DAY-14 PATCH
    final effectiveMedia = await _resolveOfflineMedia(media);

    _setState(
      _state.copyWith(
        state: PlayerState.loading,
        currentMedia: effectiveMedia,
        position: Duration.zero,
        duration: Duration.zero,
        isBuffering: true,
        errorMessage: null,
      ),
    );

    try {
      await _backend.initialize();
      await _backend.load(effectiveMedia);

      final backendState = await _backend.getCurrentState();
      _setState(
        backendState.copyWith(
          currentMedia: effectiveMedia,
          state: PlayerState.ready,
        ),
      );

      await discoverSubtitlesFor(effectiveMedia);
    } catch (e, st) {
      LogService.instance.logError('[PlayerController] load error: $e', st);
      _setState(
        _state.copyWith(
          state: PlayerState.error,
          isBuffering: false,
          errorMessage: 'Failed to load media',
        ),
      );
    }
  }

  Future<void> play() async {
    if (_state.currentMedia == null) return;
    LogService.instance.log('[PlayerController] play');

    try {
      await _backend.play();
      await BackgroundPlaybackPolicy.instance.enableBackgroundMode();
      _externalPauseMessage = null;

      _setState(
        _state.copyWith(
          state: PlayerState.playing,
          isBuffering: false,
        ),
      );

      await NotificationController.instance
          .showPlaybackNotification(_state.currentMedia!, _state);
    } catch (e, st) {
      LogService.instance.logError('[PlayerController] play error: $e', st);
    }
  }

  Future<void> pause({String? reason}) async {
    if (_state.state != PlayerState.playing &&
        _state.state != PlayerState.ready) return;

    LogService.instance.log('[PlayerController] pause (reason: $reason)');

    try {
      await _backend.pause();
      _externalPauseMessage = reason;

      _setState(
        _state.copyWith(
          state: PlayerState.paused,
          isBuffering: false,
        ),
      );

      await NotificationController.instance.updatePlaybackNotification(_state);
    } catch (e, st) {
      LogService.instance.logError('[PlayerController] pause error: $e', st);
    }
  }

  Future<void> stop() async {
    LogService.instance.log('[PlayerController] stop');

    try {
      await _backend.stop();
      await BackgroundPlaybackPolicy.instance.disableBackgroundMode();
      await NotificationController.instance.hidePlaybackNotification();

      _setState(
        _state.copyWith(
          state: PlayerState.idle,
          position: Duration.zero,
          isBuffering: false,
        ),
      );
    } catch (e, st) {
      LogService.instance.logError('[PlayerController] stop error: $e', st);
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_state.currentMedia == null) return;

    LogService.instance.log('[PlayerController] seekTo: $position');

    try {
      await _backend.seekTo(position);
      final backendState = await _backend.getCurrentState();
      _setState(backendState);
    } catch (e, st) {
      LogService.instance.logError('[PlayerController] seekTo error: $e', st);
    }
  }

  Future<void> setSpeed(double speed) async {
    LogService.instance.log('[PlayerController] setSpeed: $speed');
    try {
      await _backend.setSpeed(speed);
      final backendState = await _backend.getCurrentState();
      _setState(backendState.copyWith(speed: speed));
    } catch (e, st) {
      LogService.instance.logError('[PlayerController] setSpeed error: $e', st);
    }
  }

  // =====================================================
  // SUBTITLES (Day 13)
  // =====================================================
  /// Discover local subtitles for given [media] and auto-apply session state.
  Future<void> discoverSubtitlesFor(MediaItem media) async {
    try {
      final mediaKey = media.path;
      final session =
      SubtitleSessionRepository.instance.loadForMedia(mediaKey);

      _subtitleOffset = session.offset;

      final tracks =
      await SubtitleService.instance.findLocalSubtitlesFor(media);
      _subtitleTracks = tracks;

      SubtitleTrack? selected;

      if (session.selectedTrackId != null) {
        selected = _subtitleTracks
            .where((t) => t.id == session.selectedTrackId)
            .firstOrNull;
      }

      selected ??= await SubtitleService.instance.autoMatchSubtitle(media);

      if (selected != null) {
        await setSubtitleTrack(selected, saveSession: false);
      }

      _saveSubtitleSession();
      notifyListeners();
    } catch (e, st) {
      LogService.instance.logError(
          '[PlayerController] discoverSubtitlesFor error: $e', st);
    }
  }

  Future<void> setSubtitleTrack(SubtitleTrack? track,
      {bool saveSession = true}) async {
    _currentSubtitleTrack = null;

    if (track != null) {
      final parsed = await SubtitleService.instance.loadAndParseTrack(track);

      final index = _subtitleTracks.indexWhere((t) => t.id == parsed.id);
      if (index >= 0) {
        _subtitleTracks[index] = parsed;
      } else {
        _subtitleTracks.add(parsed);
      }

      _currentSubtitleTrack = parsed;
    }

    if (saveSession) _saveSubtitleSession();
    notifyListeners();
  }

  void setSubtitleOffset(Duration offset) {
    _subtitleOffset = offset;
    _saveSubtitleSession();
    notifyListeners();
  }

  void updateSubtitleCueTextAtPosition(Duration position, String newText) {
    final track = _currentSubtitleTrack;
    if (track == null) return;

    final cues = List<SubtitleCue>.from(track.cues);
    for (int i = 0; i < cues.length; i++) {
      final c = cues[i];
      if (position >= c.start && position <= c.end) {
        cues[i] = c.copyWith(text: newText);
        _currentSubtitleTrack = track.copyWith(cues: cues);

        final idx = _subtitleTracks.indexWhere((t) => t.id == track.id);
        if (idx >= 0) _subtitleTracks[idx] = _currentSubtitleTrack!;

        notifyListeners();
        break;
      }
    }
  }

  void _saveSubtitleSession() {
    final media = _state.currentMedia;
    if (media == null) return;

    final key = media.path;
    final prev = SubtitleSessionRepository.instance.loadForMedia(key);

    final updated = prev.copyWith(
      selectedTrackId: _currentSubtitleTrack?.id,
      offset: _subtitleOffset,
    );

    SubtitleSessionRepository.instance.saveForMedia(key, updated);
  }

  // =====================================================
  // INTERNAL HANDLERS
  // =====================================================
  void _onBackendEvent(PlayerEvent event) {
    if (_disposed) return;

    if (event is PlayerEventPosition) {
      _setState(state.copyWith(position: event.position));
    } else if (event is PlayerEventStateChanged) {
      _setState(state.copyWith(state: event.state));
    } else if (event is PlayerEventCompleted) {
      _onPlaybackCompleted();
    } else if (event is PlayerEventError) {
      _setState(
        state.copyWith(
          state: PlayerState.error,
          isBuffering: false,
          errorMessage: event.message,
        ),
      );
    }
  }

  void _onPlaybackCompleted() async {
    LogService.instance.log('[PlayerController] playback completed');

    await BackgroundPlaybackPolicy.instance.disableBackgroundMode();
    await NotificationController.instance
        .updatePlaybackNotification(state.copyWith(state: PlayerState.ended));

    _setState(state.copyWith(state: PlayerState.ended));
  }

  void _onAudioLifecycleEvent(AudioLifecycleEvent event) {
    if (_disposed) return;

    LogService.instance.log(
        '[PlayerController] AudioLifecycleEvent: ${event.type} (${event.reason})');

    onLifecycleEvent?.call(event);

    switch (event.type) {
      case AudioLifecycleEventType.becomingNoisy:
        pause(reason: 'Playback paused — headphones unplugged');
        break;
      case AudioLifecycleEventType.interrupted:
        pause(reason: 'Playback paused — interruption');
        break;
      case AudioLifecycleEventType.focusLostTemporary:
        setSpeed(0.75);
        break;
      case AudioLifecycleEventType.focusLostPermanent:
        pause(reason: 'Playback paused — focus lost');
        break;
      case AudioLifecycleEventType.focusGained:
        if (state.speed < 1.0) setSpeed(1.0);
        break;
    }
  }

  void _setState(PlayerStateData newState) {
    _state = newState;
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    try {
      await _backendSub?.cancel();
      await _audioLifecycleSub?.cancel();
      _backend.dispose();
      await BackgroundPlaybackPolicy.instance.disableBackgroundMode();
      await NotificationController.instance.hidePlaybackNotification();
    } catch (e, st) {
      LogService.instance.logError('[PlayerController] dispose error: $e', st);
    }

    super.dispose();
  }
}
