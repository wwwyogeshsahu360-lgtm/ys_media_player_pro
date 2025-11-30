import 'package:flutter/material.dart';

import '../../player/controller/player_controller.dart';
import '../models/subtitle_cue.dart';

/// SubtitleTextPosition
/// ====================
/// Where subtitles appear on the screen.
enum SubtitleTextPosition {
  top,
  middle,
  bottom,
}

/// SubtitleRenderer
/// =================
/// Listens to PlayerController and draws currently active subtitle cue.
class SubtitleRenderer extends StatefulWidget {
  final PlayerController controller;
  final double fontScale;
  final Color color;
  final SubtitleTextPosition position;

  const SubtitleRenderer({
    super.key,
    required this.controller,
    this.fontScale = 1.0,
    this.color = Colors.white,
    this.position = SubtitleTextPosition.bottom,
  });

  @override
  State<SubtitleRenderer> createState() => _SubtitleRendererState();
}

class _SubtitleRendererState extends State<SubtitleRenderer> {
  int _activeIndex = -1;
  SubtitleCue? _activeCue;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (_, __) {
          final track = widget.controller.currentSubtitleTrack;
          if (track == null || track.cues.isEmpty) {
            _activeCue = null;
            _activeIndex = -1;
            return const SizedBox.shrink();
          }

          final cues = track.cues;
          final pos =
              widget.controller.state.position + widget.controller.subtitleOffset;

          final idx = _findActiveCueIndex(cues, pos);
          if (idx != _activeIndex) {
            _activeIndex = idx;
            _activeCue = idx >= 0 && idx < cues.length ? cues[idx] : null;
          }

          if (_activeCue == null) {
            return const SizedBox.shrink();
          }

          final textStyle = _buildTextStyle(context, _activeCue!);

          return _buildPositionedText(
            context: context,
            text: _activeCue!.text,
            style: textStyle,
          );
        },
      ),
    );
  }

  int _findActiveCueIndex(List<SubtitleCue> cues, Duration position) {
    if (cues.isEmpty) return -1;

    int low = 0;
    int high = cues.length - 1;
    int candidate = -1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final cue = cues[mid];

      if (position < cue.start) {
        high = mid - 1;
      } else if (position > cue.end) {
        low = mid + 1;
      } else {
        candidate = mid;
        break;
      }
    }

    return candidate;
  }

  TextStyle _buildTextStyle(BuildContext context, SubtitleCue cue) {
    final base = DefaultTextStyle.of(context).style;
    var style = base.copyWith(
      color: widget.color,
      fontSize: 16 * widget.fontScale,
      shadows: const <Shadow>[
        Shadow(blurRadius: 4, color: Colors.black),
        Shadow(blurRadius: 4, color: Colors.black),
      ],
    );

    if (cue.bold) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (cue.italic) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }

    return style;
  }

  Widget _buildPositionedText({
    required BuildContext context,
    required String text,
    required TextStyle style,
  }) {
    Alignment alignment;
    EdgeInsets padding;

    switch (widget.position) {
      case SubtitleTextPosition.top:
        alignment = Alignment.topCenter;
        padding = const EdgeInsets.only(top: 60, left: 20, right: 20);
        break;
      case SubtitleTextPosition.middle:
        alignment = Alignment.center;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        break;
      case SubtitleTextPosition.bottom:
        alignment = Alignment.bottomCenter;
        padding = const EdgeInsets.only(bottom: 70, left: 20, right: 20);
        break;
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey<String>(text),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}
