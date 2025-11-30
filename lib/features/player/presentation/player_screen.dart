import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/services/audio_lifecycle_service.dart';
import '../../../shared/services/log_service.dart';
import '../../../shared/models/media_item.dart';
import '../../subtitles/online/online_subtitle_provider.dart';
import '../../subtitles/presentation/subtitle_renderer.dart';
import '../../subtitles/models/subtitle_track.dart';
import '../controller/player_controller.dart';
import '../backend/player_state.dart';

/// PlayerScreen — with gestures + subtitles (Day 12 + 13)
class PlayerScreen extends StatefulWidget {
  final MediaItem mediaItem;

  const PlayerScreen({super.key, required this.mediaItem});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final PlayerController _controller;

  // UI Controls
  bool _controlsVisible = true;
  bool _isLocked = false;

  // Gesture Flags
  bool _isScrubbing = false;
  bool _isVerticalDrag = false;
  bool _isHorizontalDrag = false;
  Offset? _dragStart;
  Duration _scrubStartPosition = Duration.zero;
  Duration _scrubTarget = Duration.zero;

  // Brightness / Volume (mock)
  double _volume = 0.7;
  double _brightness = 0.7;

  // Double Tap stacking
  int _doubleTapCountRight = 0;
  int _doubleTapCountLeft = 0;
  Timer? _doubleTapResetTimer;

  // Overlay previews
  String? _lifecycleMessage;
  Timer? _lifecycleMessageTimer;

  // Subtitles UI parameters (style only; logic is in PlayerController)
  double _subtitleFontScale = 1.0;
  Color _subtitleColor = Colors.white;
  SubtitleTextPosition _subtitlePosition = SubtitleTextPosition.bottom;

  @override
  void initState() {
    super.initState();
    _controller = PlayerController();

    _controller.onLifecycleEvent = _handleLifecycleEvent;

    unawaited(_controller.load(widget.mediaItem));
  }

  @override
  void dispose() {
    _controller.dispose();
    _doubleTapResetTimer?.cancel();
    _lifecycleMessageTimer?.cancel();
    super.dispose();
  }

  // =============================================================
  // LIFECYCLE EVENTS HANDLER
  // =============================================================

  void _handleLifecycleEvent(AudioLifecycleEvent event) {
    if (event.type == AudioLifecycleEventType.becomingNoisy ||
        event.type == AudioLifecycleEventType.interrupted) {
      final String msg = event.type == AudioLifecycleEventType.becomingNoisy
          ? "Playback paused — headphones unplugged"
          : "Playback paused due to interruption";

      setState(() => _lifecycleMessage = msg);

      _lifecycleMessageTimer?.cancel();
      _lifecycleMessageTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _lifecycleMessage = null);
      });
    }
  }

  // =============================================================
  // CONTROLS VISIBILITY
  // =============================================================

  void _toggleControls() {
    if (_isLocked) return;
    setState(() => _controlsVisible = !_controlsVisible);
  }

  // =============================================================
  // DOUBLE TAP SEEK (LEFT/RIGHT ZONES)
  // =============================================================

  void _handleDoubleTapLeft() {
    if (_isLocked) return;

    _doubleTapCountLeft++;
    _resetDoubleTapAfterDelay();

    final jumpSeconds = 10 * _doubleTapCountLeft;

    final newPos =
        _controller.state.position - Duration(seconds: jumpSeconds);

    unawaited(_controller
        .seekTo(newPos < Duration.zero ? Duration.zero : newPos));

    _showSeekOverlay(isForward: false, jump: jumpSeconds);
  }

  void _handleDoubleTapRight() {
    if (_isLocked) return;

    _doubleTapCountRight++;
    _resetDoubleTapAfterDelay();

    final jumpSeconds = 10 * _doubleTapCountRight;

    final newPos =
        _controller.state.position + Duration(seconds: jumpSeconds);

    final capped = newPos > _controller.state.duration
        ? _controller.state.duration
        : newPos;

    unawaited(_controller.seekTo(capped));

    _showSeekOverlay(isForward: true, jump: jumpSeconds);
  }

  void _resetDoubleTapAfterDelay() {
    _doubleTapResetTimer?.cancel();
    _doubleTapResetTimer = Timer(const Duration(seconds: 1), () {
      _doubleTapCountLeft = 0;
      _doubleTapCountRight = 0;
    });
  }

  void _showSeekOverlay({required bool isForward, required int jump}) {
    final overlay = isForward ? "+$jump sec →" : "← -$jump sec";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.black87,
        content: Text(
          overlay,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // =============================================================
  // VERTICAL DRAG: BRIGHTNESS (LEFT) & VOLUME (RIGHT)
  // =============================================================

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isLocked) return;
    _isVerticalDrag = true;
    _dragStart = details.localPosition;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isVerticalDrag || _isLocked) return;
    if (_dragStart == null) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final dx = _dragStart!.dx;

    final isLeft = dx < screenWidth * 0.33; // brightness zone
    final isRight = dx > screenWidth * 0.66; // volume zone

    final delta = details.delta.dy;

    if (isLeft) {
      _brightness = (_brightness - delta / 300).clamp(0.0, 1.0);
    } else if (isRight) {
      _volume = (_volume - delta / 300).clamp(0.0, 1.0);
    }

    setState(() {});
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _isVerticalDrag = false;
    _dragStart = null;
  }

  // =============================================================
  // HORIZONTAL DRAG SEEK (SCRUBBING)
  // =============================================================

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isLocked) return;
    _isHorizontalDrag = true;
    _dragStart = details.localPosition;
    _isScrubbing = true;
    _scrubStartPosition = _controller.state.position;
    _scrubTarget = _scrubStartPosition;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isHorizontalDrag || _isLocked || _dragStart == null) return;

    final deltaX = details.delta.dx;
    final width = MediaQuery.of(context).size.width;
    final totalDuration = max(
      1,
      _controller.state.duration.inMilliseconds,
    ).toDouble();

    final deltaMs = (deltaX / width) * totalDuration * 1.2;

    final newPos =
        _scrubStartPosition.inMilliseconds + deltaMs;

    final clamped = newPos.clamp(0, totalDuration).toInt();

    setState(() {
      _scrubTarget = Duration(milliseconds: clamped);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isHorizontalDrag) return;

    unawaited(_controller.seekTo(_scrubTarget));
    _isScrubbing = false;
    _isHorizontalDrag = false;
    _dragStart = null;
    setState(() {});
  }

  // =============================================================
  // SUBTITLE SETTINGS SHEET
  // =============================================================

  void _openSubtitleSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final tracks = _controller.subtitleTracks;
            final current = _controller.currentSubtitleTrack;
            final offset = _controller.subtitleOffset;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.subtitles, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Subtitles',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _controller.setSubtitleTrack(null);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Disable'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Track list
                  if (tracks.isEmpty)
                    ListTile(
                      title: const Text(
                        'No local subtitles found',
                        style: TextStyle(color: Colors.white70),
                      ),
                      subtitle: const Text(
                        'Tap "Auto-match" or "Search online" to add.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: tracks.length,
                          itemBuilder: (_, index) {
                            final t = tracks[index];
                            final selected = t.id == current?.id;
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? Colors.orangeAccent
                                    : Colors.white70,
                              ),
                              title: Text(
                                t.label,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                t.languageCode ?? t.sourceType.name,
                                style:
                                const TextStyle(color: Colors.white54),
                              ),
                              onTap: () async {
                                await _controller.setSubtitleTrack(t);
                                if (mounted) setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Offset controls
                  Row(
                    children: [
                      const Text(
                        'Offset',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${offset.inMilliseconds} ms',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          final newOffset =
                              offset - const Duration(milliseconds: 500);
                          _controller.setSubtitleOffset(newOffset);
                        },
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {
                          final newOffset =
                              offset + const Duration(milliseconds: 500);
                          _controller.setSubtitleOffset(newOffset);
                        },
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  Slider(
                    value: offset.inMilliseconds.toDouble().clamp(-10000, 10000),
                    min: -10000,
                    max: 10000,
                    onChanged: (v) {
                      _controller
                          .setSubtitleOffset(Duration(milliseconds: v.toInt()));
                    },
                  ),

                  const SizedBox(height: 8),

                  // Font size + position
                  Row(
                    children: [
                      const Text(
                        'Font size',
                        style: TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          value: _subtitleFontScale,
                          min: 0.8,
                          max: 1.6,
                          onChanged: (v) {
                            setState(() {
                              _subtitleFontScale = v;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Position',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Top'),
                        selected: _subtitlePosition == SubtitleTextPosition.top,
                        onSelected: (_) {
                          setState(() {
                            _subtitlePosition = SubtitleTextPosition.top;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Middle'),
                        selected:
                        _subtitlePosition == SubtitleTextPosition.middle,
                        onSelected: (_) {
                          setState(() {
                            _subtitlePosition = SubtitleTextPosition.middle;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Bottom'),
                        selected:
                        _subtitlePosition == SubtitleTextPosition.bottom,
                        onSelected: (_) {
                          setState(() {
                            _subtitlePosition = SubtitleTextPosition.bottom;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Actions row: auto-match, search online, edit cue
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await _controller
                              .discoverSubtitlesFor(widget.mediaItem);
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.auto_fix_high,
                            color: Colors.orangeAccent),
                        label: const Text(
                          'Auto-match',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _searchOnlineSubtitles,
                        icon: const Icon(Icons.cloud_download,
                            color: Colors.lightBlueAccent),
                        label: const Text(
                          'Search online',
                          style: TextStyle(color: Colors.lightBlueAccent),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _editActiveCueText,
                        child: const Text(
                          'Edit current line',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _searchOnlineSubtitles() async {
    try {
      final candidates =
      await OnlineSubtitleProvider.instance.searchOnline(widget.mediaItem);

      if (!mounted) return;
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No online subtitles found (mock provider).'),
          ),
        );
        return;
      }

      SubtitleTrack? chosen;

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: const Text(
              'Choose online subtitle',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: candidates.length,
                itemBuilder: (_, index) {
                  final t = candidates[index];
                  return ListTile(
                    leading: const Icon(Icons.subtitles,
                        color: Colors.white70),
                    title: Text(
                      t.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      t.languageCode ?? 'Unknown language',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () {
                      chosen = t;
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      if (chosen == null) return;

      final downloaded = await OnlineSubtitleProvider.instance
          .downloadToLocalFile(chosen!, widget.mediaItem);

      await _controller.setSubtitleTrack(downloaded);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Subtitle "${downloaded.label}" applied.',
            ),
          ),
        );
      }
    } catch (e, st) {
      LogService.instance
          .logError('[PlayerScreen] _searchOnlineSubtitles error: $e', st);
    }
  }

  Future<void> _editActiveCueText() async {
    final cues = _controller.currentSubtitleCues;
    if (cues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active subtitle to edit.'),
        ),
      );
      return;
    }

    final position = _controller.state.position;
    final active = cues.firstWhere(
          (c) => position >= c.start && position <= c.end,
      orElse: () => cues.first,
    );

    final controller = TextEditingController(text: active.text);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'Edit subtitle line',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter new subtitle text',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  _controller.updateSubtitleCueTextAtPosition(
                    position,
                    text,
                  );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // =============================================================
  // UI BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                _buildVideoArea(),
                _buildGestureLayer(),
                // Subtitles layer
                SubtitleRenderer(
                  controller: _controller,
                  fontScale: _subtitleFontScale,
                  color: _subtitleColor,
                  position: _subtitlePosition,
                ),
                if (_controlsVisible) _buildControls(),
                if (_isLocked) _buildLockBadge(),
                if (_lifecycleMessage != null) _buildLifecycleOverlay(),
                if (_isScrubbing) _buildScrubPreview(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------------
  // VIDEO CONTAINER (Dummy)
  // ------------------------------

  Widget _buildVideoArea() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_circle_fill,
        color: Colors.white54,
        size: 80,
      ),
    );
  }

  // ------------------------------
  // GESTURE LAYER
  // ------------------------------

  Widget _buildGestureLayer() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      // TAPS
      onTap: _toggleControls,

      // DOUBLE TAPS
      onDoubleTapDown: (details) {
        final w = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < w * 0.33) {
          _handleDoubleTapLeft();
        } else if (details.localPosition.dx > w * 0.66) {
          _handleDoubleTapRight();
        }
      },

      // VERTICAL DRAG
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,

      // HORIZONTAL DRAG SEEKING
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
    );
  }

  // ------------------------------
  // SCRUB PREVIEW
  // ------------------------------

  Widget _buildScrubPreview() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDuration(_scrubTarget),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // ------------------------------
  // CONTROLS (TOP + BOTTOM)
  // ------------------------------

  Widget _buildControls() {
    return IgnorePointer(
      ignoring: _isLocked,
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            // TOP BAR
            Container(
              padding: const EdgeInsets.only(
                  top: 40, left: 12, right: 12, bottom: 10),
              color: Colors.black45,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.mediaItem.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isLocked ? Icons.lock : Icons.lock_open,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => _isLocked = !_isLocked),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // BOTTOM BAR
            Container(
              padding: const EdgeInsets.only(
                  bottom: 30, left: 16, right: 16, top: 10),
              color: Colors.black45,
              child: Column(
                children: [
                  Slider(
                    value: _controller.state.position.inMilliseconds
                        .clamp(0, _controller.state.duration.inMilliseconds)
                        .toDouble(),
                    min: 0,
                    max:
                    max(1, _controller.state.duration.inMilliseconds)
                        .toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _scrubTarget =
                            Duration(milliseconds: value.toInt());
                      });
                    },
                    onChangeEnd: (value) {
                      unawaited(
                        _controller.seekTo(
                          Duration(milliseconds: value.toInt()),
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_controller.state.position),
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        _formatDuration(_controller.state.duration),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10,
                            color: Colors.white, size: 32),
                        onPressed: () => _controller.seekTo(
                          _controller.state.position -
                              const Duration(seconds: 10),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _controller.state.state == PlayerState.playing
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: Colors.white,
                          size: 55,
                        ),
                        onPressed: () {
                          if (_controller.state.state ==
                              PlayerState.playing) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10,
                            color: Colors.white, size: 32),
                        onPressed: () => _controller.seekTo(
                          _controller.state.position +
                              const Duration(seconds: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.subtitles,
                            color: Colors.white),
                        onPressed: _openSubtitleSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // LOCK BADGE
  // ------------------------------

  Widget _buildLockBadge() {
    return Positioned(
      top: 80,
      right: 20,
      child: Row(
        children: const [
          Icon(Icons.lock, color: Colors.white70, size: 22),
          SizedBox(width: 6),
          Text(
            "Controls Locked",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // LIFECYCLE MESSAGE OVERLAY
  // ------------------------------

  Widget _buildLifecycleOverlay() {
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.headset_off, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                _lifecycleMessage ?? "",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // HELPERS
  // =============================================================

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return "$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "$m:${s.toString().padLeft(2, '0')}";
  }
}
