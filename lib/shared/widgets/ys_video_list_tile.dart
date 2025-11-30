// lib/shared/widgets/ys_video_list_tile.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../services/thumbnail_service.dart';

/// YSVideoListTile
/// ===============
/// Reusable video list tile with:
/// - Thumbnail (from ThumbnailService)
/// - Title
/// - Duration
/// - Optional download badge/progress line
/// - Optional trailing widget (e.g., download button)
class YSVideoListTile extends StatelessWidget {
  const YSVideoListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.trailing,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress,
  });

  /// Video metadata.
  final MediaItem item;

  /// Tap callback (open player, etc.).
  final VoidCallback onTap;

  final VoidCallback? onLongPress;

  /// Optional trailing widget (download icon, menu, etc.).
  final Widget? trailing;

  /// Whether this item is fully downloaded for offline playback.
  final bool isDownloaded;

  /// Whether this item is currently being downloaded.
  final bool isDownloading;

  /// Download progress as 0.0–1.0 (if known).
  final double? downloadProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final Duration d = item.duration;
    final String durationText =
        '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

    // Build subtitle: duration + an optional download status line.
    final List<Widget> subtitleChildren = <Widget>[
      Text(
        durationText,
        style: textTheme.bodySmall,
      ),
    ];

    if (isDownloaded) {
      subtitleChildren.add(
        const SizedBox(height: 2),
      );
      subtitleChildren.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_done_rounded,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Downloaded',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (isDownloading) {
      final double progressPercent =
          (downloadProgress != null ? (downloadProgress!.clamp(0.0, 1.0)) : 0.0) * 100;
      subtitleChildren.add(
        const SizedBox(height: 2),
      );
      subtitleChildren.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: downloadProgress != null
                    ? downloadProgress!.clamp(0.0, 1.0)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Downloading • ${progressPercent.toStringAsFixed(0)}%',
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: _buildThumbnail(context),
      title: Text(
        item.fileName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: subtitleChildren,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return FutureBuilder<String?>(
      future: ThumbnailService.instance.getThumbnailPathForMedia(item),
      builder: (_, snapshot) {
        final cs = Theme.of(context).colorScheme;

        final String? path = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting || path == null || path.isEmpty) {
          return _placeholder(cs);
        }

        final file = File(path);
        if (!file.existsSync()) {
          return _placeholder(cs);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(cs),
          ),
        );
      },
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_rounded,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
