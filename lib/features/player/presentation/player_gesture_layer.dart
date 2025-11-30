import 'package:flutter/material.dart';

import '../../../shared/services/log_service.dart';

/// Direction used for double-tap quick seek.
enum QuickSeekDirection {
  backward,
  forward,
}

/// Internal enum to keep track of active drag axis.
enum _ActiveDragAxis {
  horizontal,
  vertical,
}

/// Internal enum to mark which vertical control is active.
enum _VerticalControlType {
  brightness,
  volume,
}

/// PlayerGestureLayer
/// ==================
///
/// This widget sits on top of the video area and handles:
/// - Single tap (toggle controls / unlock)
/// - Double-tap left/right (quick seek back/forward)
/// - Vertical drag on left (brightness)
/// - Vertical drag on right (volume)
/// - Horizontal drag (scrub/seek preview)
///
/// All real logic (seek, volume, brightness, etc.) is delegated to callbacks.
class PlayerGestureLayer extends StatefulWidget {
  const PlayerGestureLayer({
    super.key,
    required this.locked,
    required this.onSingleTap,
    required this.onQuickSeek,
    required this.onSeekScrubStart,
    required this.onSeekScrubUpdate,
    required this.onSeekScrubEnd,
    required this.onBrightnessDelta,
    required this.onVolumeDelta,
  });

  /// If true, all gestures except single-tap are ignored.
  final bool locked;

  /// Single tap anywhere toggles controls / unlocks (handled in PlayerScreen).
  final VoidCallback onSingleTap;

  /// Double-tap quick seek: left = backward, right = forward.
  final void Function(QuickSeekDirection direction) onQuickSeek;

  /// Horizontal scrub callbacks.
  final VoidCallback onSeekScrubStart;
  final void Function(double relativeDelta) onSeekScrubUpdate;
  final void Function(double relativeDelta) onSeekScrubEnd;

  /// Vertical control callbacks. deltaFraction ~ -1..+1 relative to screen height.
  final void Function(double deltaFraction) onBrightnessDelta;
  final void Function(double deltaFraction) onVolumeDelta;

  @override
  State<PlayerGestureLayer> createState() => _PlayerGestureLayerState();
}

class _PlayerGestureLayerState extends State<PlayerGestureLayer> {
  // Layout info
  double _width = 1;
  double _height = 1;

  // Drag state
  _ActiveDragAxis? _activeAxis;
  _VerticalControlType? _verticalType;
  Offset _panStartLocal = Offset.zero;
  Offset _panAccumulated = Offset.zero;
  double _horizontalAccumulated = 0;

  static const double _slop = 12.0; // movement threshold to decide axis

  void _handleTapUp(TapUpDetails details) {
    // Single-tap is always passed through (even when locked),
    // so PlayerScreen can unlock / toggle controls.
    widget.onSingleTap();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    if (widget.locked) return;

    try {
      final dx = details.localPosition.dx;
      final w = _width <= 0 ? 1 : _width;

      const double sideFraction = 0.35; // 35% on each side for quick seek zones
      final double leftBoundary = w * sideFraction;
      final double rightBoundary = w * (1 - sideFraction);

      if (dx <= leftBoundary) {
        widget.onQuickSeek(QuickSeekDirection.backward);
      } else if (dx >= rightBoundary) {
        widget.onQuickSeek(QuickSeekDirection.forward);
      } else {
        // Center double-tap is currently unused (could be play/pause later).
      }
    } catch (e, st) {
      LogService.instance
          .logError('[PlayerGestureLayer] DoubleTap error: $e', st);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.locked) return;

    _activeAxis = null;
    _verticalType = null;
    _panAccumulated = Offset.zero;
    _horizontalAccumulated = 0;
    _panStartLocal = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.locked) return;

    _panAccumulated += details.delta;

    if (_width <= 0 || _height <= 0) {
      return;
    }

    // Decide axis once movement exceeds the slop.
    if (_activeAxis == null) {
      if (_panAccumulated.distance < _slop) {
        return;
      }
      if (_panAccumulated.dx.abs() > _panAccumulated.dy.abs()) {
        _activeAxis = _ActiveDragAxis.horizontal;
        // Start horizontal scrub.
        widget.onSeekScrubStart();
      } else {
        _activeAxis = _ActiveDragAxis.vertical;

        final double startX = _panStartLocal.dx;
        if (startX < _width / 2) {
          _verticalType = _VerticalControlType.brightness;
        } else {
          _verticalType = _VerticalControlType.volume;
        }
      }
    }

    if (_activeAxis == _ActiveDragAxis.vertical) {
      // Up = increase, Down = decrease
      final double deltaFraction = -details.delta.dy / _height;

      if (_verticalType == _VerticalControlType.brightness) {
        widget.onBrightnessDelta(deltaFraction);
      } else {
        widget.onVolumeDelta(deltaFraction);
      }
    } else if (_activeAxis == _ActiveDragAxis.horizontal) {
      _horizontalAccumulated += details.delta.dx;
      final double relative = _horizontalAccumulated / _width;
      widget.onSeekScrubUpdate(relative);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.locked) return;

    if (_activeAxis == _ActiveDragAxis.horizontal) {
      final double relative = _horizontalAccumulated / (_width <= 0 ? 1 : _width);
      widget.onSeekScrubEnd(relative);
    }

    _activeAxis = null;
    _verticalType = null;
    _panAccumulated = Offset.zero;
    _horizontalAccumulated = 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _width = constraints.maxWidth;
        _height = constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: _handleTapUp,
          onDoubleTapDown: _handleDoubleTapDown,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
