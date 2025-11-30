// lib/core/icons/ys_icons.dart
import 'package:flutter/material.dart';

/// Logical icon registry for YS Media Player Pro.
/// If in future you add SVG icons, you can map them here.
class YSIcons {
  const YSIcons._();

  // Navigation
  static const IconData videos = Icons.video_library_rounded;
  static const IconData folders = Icons.folder_rounded;
  static const IconData playlists = Icons.playlist_play_rounded;
  static const IconData settings = Icons.settings_rounded;

  // Player
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData seekForward = Icons.forward_10_rounded;
  static const IconData seekBackward = Icons.replay_10_rounded;
  static const IconData speed = Icons.speed_rounded;
  static const IconData subtitles = Icons.subtitles_rounded;

  // Downloads
  static const IconData download = Icons.download_rounded;
  static const IconData downloading = Icons.downloading_rounded;
  static const IconData downloadDone = Icons.check_circle_rounded;

  // Misc
  static const IconData theme = Icons.brightness_6_rounded;
  static const IconData language = Icons.language_rounded;
  static const IconData feedback = Icons.feedback_rounded;
}
