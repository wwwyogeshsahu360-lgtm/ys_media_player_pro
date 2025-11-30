// lib/features/videos/presentation/pages/videos_tab.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/layout_utils.dart';

import '../../../../shared/controllers/library_controller.dart';
import '../../../../shared/models/media_item.dart';
import '../../../../shared/widgets/ys_video_list_tile.dart';
import '../../../../shared/services/thumbnail_service.dart';

import '../../../player/presentation/player_screen.dart';
import '../../../downloads/data/download_manager.dart';
import '../../../downloads/domain/download_item.dart';
import '../../../downloads/domain/download_status.dart';

// 👇 Day-17 cast device picker hook
import '../../../cast/presentation/cast_device_picker_sheet.dart';

class VideosTab extends StatefulWidget {
  const VideosTab({
    super.key,
    required this.controller,
  });

  final LibraryController controller;

  @override
  State<VideosTab> createState() => _VideosTabState();
}

enum _VideoSortMode { title, dateAdded, duration }

class _VideosTabState extends State<VideosTab> {
  LibraryController get _controller => widget.controller;

  bool _isGridView = false;
  bool _showSearchBar = false;
  String _searchQuery = '';
  _VideoSortMode _sortMode = _VideoSortMode.dateAdded;

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant VideosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _retry() => _controller.refresh();
  Future<void> _requestPermissionAndScan() => _controller.refreshFromDevice();

  void _toggleViewMode() => setState(() => _isGridView = !_isGridView);

  void _setSortMode(_VideoSortMode mode) => setState(() => _sortMode = mode);

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onSearchChanged(String value) =>
      setState(() => _searchQuery = value.trim());

  bool _isRemote(MediaItem item) {
    final p = item.path.toLowerCase();
    return p.startsWith("http://") || p.startsWith("https://");
  }

  /// --------------------------------------------------------------
  /// DOWNLOAD HANDLER – fixed BuildContext across async gap
  /// --------------------------------------------------------------
  Future<void> _handleDownload(MediaItem item) async {
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (!_isRemote(item)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('videos_download_only_remote'))),
      );
      return;
    }

    final DownloadItem? existing =
    DownloadManager.instance.getByUrl(item.path);

    if (existing != null &&
        (existing.status == DownloadStatus.downloading ||
            existing.status == DownloadStatus.queued ||
            existing.status == DownloadStatus.paused ||
            existing.status == DownloadStatus.completed)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.tr('videos_download_already')} '
                '${existing.status.label.toLowerCase()}',
          ),
        ),
      );
      return;
    }

    await DownloadManager.instance.enqueueDownload(
      url: item.path,
      mediaId: item.id,
      suggestedFileName: item.fileName,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.tr('videos_download_added'))),
    );
  }

  // ============= PERMISSION VIEW =============
  Widget _buildPermissionRequiredView(
      BuildContext context,
      String? message,
      ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              l10n.tr('videos_allow_access_title'),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? l10n.tr('videos_allow_access_body'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _requestPermissionAndScan,
              icon: const Icon(Icons.videocam),
              label: Text(l10n.tr('videos_grant_permission')),
            ),
          ],
        ),
      ),
    );
  }

  // ============= HEADER BAR =============
  Widget _buildHeaderBar(BuildContext context, int totalCount) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final String sortLabel = () {
      switch (_sortMode) {
        case _VideoSortMode.title:
          return l10n.tr('videos_sort_title');
        case _VideoSortMode.dateAdded:
          return l10n.tr('videos_sort_date');
        case _VideoSortMode.duration:
          return l10n.tr('videos_sort_duration');
      }
    }();

    return Material(
      color: cs.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: _showSearchBar
                  ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.tr('videos_search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSearchBar,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('videos_header_all'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalCount • $sortLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.tr('videos_search_hint'),
              icon: Icon(_showSearchBar ? Icons.close : Icons.search),
              onPressed: _toggleSearchBar,
            ),
            IconButton(
              tooltip: _isGridView ? 'List' : 'Grid',
              icon: Icon(
                _isGridView
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
              ),
              onPressed: _toggleViewMode,
            ),
            PopupMenuButton<_VideoSortMode>(
              tooltip: "Sort",
              icon: const Icon(Icons.sort_rounded),
              onSelected: _setSortMode,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _VideoSortMode.title,
                  child: Text(l10n.tr('videos_sort_title')),
                ),
                PopupMenuItem(
                  value: _VideoSortMode.dateAdded,
                  child: Text(l10n.tr('videos_sort_date')),
                ),
                PopupMenuItem(
                  value: _VideoSortMode.duration,
                  child: Text(l10n.tr('videos_sort_duration')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============= SEARCH + SORT =============
  List<MediaItem> _applySearchAndSort(List<MediaItem> videos) {
    List<MediaItem> result = List.of(videos);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (v) => v.fileName.toLowerCase().contains(q),
      )
          .toList();
    }

    result.sort((a, b) {
      switch (_sortMode) {
        case _VideoSortMode.title:
          return a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase());
        case _VideoSortMode.dateAdded:
          return b.dateAdded.compareTo(a.dateAdded);
        case _VideoSortMode.duration:
          return b.duration.inMilliseconds
              .compareTo(a.duration.inMilliseconds);
      }
    });

    return result;
  }

  // ============= GRID VIEW =============
  Widget _buildGridView(List<MediaItem> videos) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = LayoutUtils.gridColumnsForWidth(width);

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: videos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, int index) {
        final MediaItem item = videos[index];
        final DownloadItem? dl =
        DownloadManager.instance.getByUrl(item.path);

        final bool isRemote = _isRemote(item);
        final bool isDownloaded = dl?.status == DownloadStatus.completed;
        final bool isDownloading = dl?.status == DownloadStatus.downloading;
        final double? progress = dl?.progress;

        return _VideoGridItem(
          item: item,
          hasDownload: dl != null,
          isCompleted: isDownloaded,
          isDownloading: isDownloading,
          progress: progress,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(mediaItem: item),
              ),
            );
          },
          // Day-17: long-press to open cast device picker
          onLongPress: () {
            showCastDevicePickerSheet(context, mediaItem: item);
          },
          onDownloadTap: isRemote ? () => _handleDownload(item) : null,
        );
      },
    );
  }

  // ============= LIST VIEW =============
  Widget _buildListView(List<MediaItem> videos) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: videos.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, int index) {
        final MediaItem item = videos[index];
        final DownloadItem? dl =
        DownloadManager.instance.getByUrl(item.path);

        final bool isRemote = _isRemote(item);
        final bool isDownloaded = dl?.status == DownloadStatus.completed;
        final bool isDownloading = dl?.status == DownloadStatus.downloading;
        final double? progress = dl?.progress;

        return YSVideoListTile(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(mediaItem: item),
              ),
            );
          },
          // Day-17: long-press -> cast picker
          onLongPress: () {
            showCastDevicePickerSheet(context, mediaItem: item);
          },
          trailing: isRemote
              ? IconButton(
            icon: Icon(
              dl == null
                  ? Icons.download_rounded
                  : dl.status == DownloadStatus.completed
                  ? Icons.check_circle_rounded
                  : Icons.downloading_rounded,
            ),
            onPressed: () => _handleDownload(item),
          )
              : null,
          isDownloaded: isDownloaded,
          isDownloading: isDownloading,
          downloadProgress: progress,
        );
      },
    );
  }

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final bool isLoading = _controller.isLoading;
    final String? errorMessage = _controller.errorMessage;
    final bool hasPermissionIssue = _controller.hasPermissionIssue;

    final List<MediaItem> videos = _controller.videos.toList();

    if (isLoading && videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
            const SizedBox(height: 16),
            Text(l10n.tr('videos_scanning')),
          ],
        ),
      );
    }

    if (hasPermissionIssue && videos.isEmpty) {
      return _buildPermissionRequiredView(context, errorMessage);
    }

    if (errorMessage != null && videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              l10n.tr('videos_unable_load'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _retry,
              child: Text(l10n.tr('videos_retry')),
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 72,
              color: cs.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tr('videos_none_found'),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final List<MediaItem> finalList = _applySearchAndSort(videos);

    return Column(
      children: [
        _buildHeaderBar(context, videos.length),
        Expanded(
          child: finalList.isEmpty
              ? Center(
            child: Text(l10n.tr('videos_no_match')),
          )
              : _isGridView
              ? _buildGridView(finalList)
              : _buildListView(finalList),
        ),
      ],
    );
  }
}

// ==================== GRID ITEM WIDGET ====================
class _VideoGridItem extends StatelessWidget {
  const _VideoGridItem({
    required this.item,
    required this.onTap,
    required this.hasDownload,
    required this.isCompleted,
    this.onDownloadTap,
    this.isDownloading = false,
    this.progress,
    this.onLongPress,
  });

  final MediaItem item;
  final VoidCallback onTap;
  final bool hasDownload;
  final bool isCompleted;
  final bool isDownloading;
  final double? progress;
  final VoidCallback? onDownloadTap;

  // Day-17: for cast picker
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final Duration d = item.duration;
    final String durationText =
        '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.8),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // THUMBNAIL + DOWNLOAD BADGES
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _GridThumbnailWidget(item: item),
                  ),
                  if (hasDownload)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.downloading_rounded,
                        size: 22,
                        color: cs.primary,
                      ),
                    ),
                  if (isDownloading && progress != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        minHeight: 3,
                      ),
                    ),
                  if (onDownloadTap != null)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: IconButton(
                        icon: const Icon(Icons.download_rounded, size: 20),
                        color: cs.onSurface,
                        style: IconButton.styleFrom(
                          backgroundColor:
                          cs.surface.withValues(alpha: 0.8),
                          minimumSize: const Size(30, 30),
                        ),
                        onPressed: onDownloadTap,
                      ),
                    ),
                ],
              ),
            ),

            // TITLE
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                item.fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // DURATION
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Text(
                durationText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== THUMBNAIL WIDGET ====================
class _GridThumbnailWidget extends StatelessWidget {
  const _GridThumbnailWidget({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ThumbnailService.instance.getThumbnailPathForMedia(item),
      builder: (_, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _placeholder(context);
        }

        final String? path = snapshot.data;
        if (path == null || path.isEmpty) {
          return _placeholder(context);
        }

        final File file = File(path);
        if (!file.existsSync()) {
          return _placeholder(context);
        }

        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.movie,
        size: 42,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
