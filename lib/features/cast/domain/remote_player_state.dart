// lib/features/cast/domain/remote_player_state.dart

/// Lightweight remote player state used by cast / DLNA / HTTP control.
///
/// NOTE: This is intentionally independent of the local PlayerController
/// so that we don't break your existing player implementation. Later you
/// can map between the two.
class RemotePlayerState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? mediaId;
  final String? mediaTitle;

  const RemotePlayerState({
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.mediaId,
    this.mediaTitle,
  });

  factory RemotePlayerState.initial() => const RemotePlayerState(
    isPlaying: false,
    position: Duration.zero,
    duration: Duration.zero,
  );

  RemotePlayerState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? mediaId,
    String? mediaTitle,
  }) {
    return RemotePlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      mediaId: mediaId ?? this.mediaId,
      mediaTitle: mediaTitle ?? this.mediaTitle,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'isPlaying': isPlaying,
    'positionMs': position.inMilliseconds,
    'durationMs': duration.inMilliseconds,
    'mediaId': mediaId,
    'mediaTitle': mediaTitle,
  };

  static RemotePlayerState fromJson(Map<String, dynamic> json) {
    return RemotePlayerState(
      isPlaying: json['isPlaying'] as bool? ?? false,
      position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      mediaId: json['mediaId'] as String?,
      mediaTitle: json['mediaTitle'] as String?,
    );
  }
}
