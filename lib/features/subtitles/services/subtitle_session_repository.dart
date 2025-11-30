import 'dart:collection';

/// SubtitleSessionState
/// ====================
/// Session-level config per media (no disk persistence yet).
class SubtitleSessionState {
  final String? selectedTrackId;
  final Duration offset;

  const SubtitleSessionState({
    required this.selectedTrackId,
    required this.offset,
  });

  SubtitleSessionState copyWith({
    String? selectedTrackId,
    Duration? offset,
  }) {
    return SubtitleSessionState(
      selectedTrackId: selectedTrackId ?? this.selectedTrackId,
      offset: offset ?? this.offset,
    );
  }

  static SubtitleSessionState initial() =>
      const SubtitleSessionState(selectedTrackId: null, offset: Duration.zero);
}

/// SubtitleSessionRepository
/// =========================
/// Keeps subtitle preferences per media path for the current app session.
class SubtitleSessionRepository {
  SubtitleSessionRepository._internal();

  static final SubtitleSessionRepository instance =
  SubtitleSessionRepository._internal();

  final Map<String, SubtitleSessionState> _store =
  HashMap<String, SubtitleSessionState>();

  SubtitleSessionState loadForMedia(String mediaKey) {
    return _store[mediaKey] ?? SubtitleSessionState.initial();
  }

  void saveForMedia(String mediaKey, SubtitleSessionState state) {
    _store[mediaKey] = state;
  }
}
