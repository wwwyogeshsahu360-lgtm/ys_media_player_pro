import 'package:flutter/material.dart';

import '../../../../shared/controllers/library_controller.dart';
import '../../../../shared/models/folder_item.dart';
import '../../../../shared/services/ignored_folders_service.dart';
import '../../../../shared/widgets/ys_folder_list_tile.dart';
import 'folder_videos_screen.dart';

/// FoldersTab
/// ==========
/// Advanced folder-centric UI:
/// - Shows folder list with counts and sizes
/// - Handles loading, error, permission and empty states
/// - Supports sorting (name, count, size)
/// - Long-press to hide/ignore folder (locally persisted)
/// - Tap to open FolderVideosScreen with videos inside the folder.
class FoldersTab extends StatefulWidget {
  const FoldersTab({
    super.key,
    required this.controller,
  });

  final LibraryController controller;

  @override
  State<FoldersTab> createState() => _FoldersTabState();
}

enum _FolderSortMode { name, count, size }

class _FoldersTabState extends State<FoldersTab> {
  LibraryController get _controller => widget.controller;

  _FolderSortMode _sortMode = _FolderSortMode.name;
  Set<String> _ignoredFolderPaths = <String>{};
  bool _loadingIgnored = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _loadIgnoredFolders();
  }

  @override
  void didUpdateWidget(covariant FoldersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadIgnoredFolders() async {
    final set = await IgnoredFoldersService.instance.getIgnoredFolders();
    if (!mounted) return;
    setState(() {
      _ignoredFolderPaths = set;
      _loadingIgnored = false;
    });
  }

  Future<void> _refreshFromDevice() => _controller.refreshFromDevice();
  Future<void> _retry() => _controller.refresh();

  void _setSortMode(_FolderSortMode mode) {
    setState(() => _sortMode = mode);
  }

  List<FolderItem> _getVisibleSortedFolders() {
    final List<FolderItem> all = _controller.folders.toList();
    // Filter out ignored folders
    List<FolderItem> filtered = all
        .where((f) => !_ignoredFolderPaths.contains(f.path))
        .toList();

    // Sort
    filtered.sort((a, b) {
      switch (_sortMode) {
        case _FolderSortMode.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _FolderSortMode.count:
          return b.videoCount.compareTo(a.videoCount);
        case _FolderSortMode.size:
          return b.totalSize.compareTo(a.totalSize);
      }
    });

    return filtered;
  }

  void _openFolder(FolderItem folder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FolderVideosScreen(
          folder: folder,
          controller: _controller,
        ),
      ),
    );
  }

  Future<void> _onLongPressFolder(FolderItem folder) async {
    final String path = folder.path;
    final bool alreadyIgnored = _ignoredFolderPaths.contains(path);

    // Show bottom sheet with hide option (unhide in future)
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${folder.videoCount} video${folder.videoCount == 1 ? '' : 's'}',
                  ),
                ),
                const Divider(),
                if (!alreadyIgnored)
                  ListTile(
                    leading: const Icon(Icons.visibility_off),
                    title: const Text('Hide this folder'),
                    subtitle: const Text(
                      'This folder will be hidden from the folders list.',
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await IgnoredFoldersService.instance
                          .addIgnoredFolder(path);
                      await _loadIgnoredFolders();
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Folder hidden: ${folder.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.visibility),
                    title: const Text('Unhide this folder'),
                    subtitle: const Text(
                      'Show this folder again in the folders list.',
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await IgnoredFoldersService.instance
                          .removeIgnoredFolder(path);
                      await _loadIgnoredFolders();
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Folder unhidden: ${folder.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bool isLoading = _controller.isLoading;
    final String? errorMessage = _controller.errorMessage;
    final bool hasPermissionIssue = _controller.hasPermissionIssue;

    if (_loadingIgnored) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
        ),
      );
    }

    final List<FolderItem> folders = _getVisibleSortedFolders();

    // Loading state
    if (isLoading && folders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Scanning folders...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Permission issue
    if (hasPermissionIssue && folders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Allow access to your storage',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ??
                    'YS Media Player Pro needs access to your device to detect folders.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _refreshFromDevice,
                icon: const Icon(Icons.videocam),
                label: const Text('Grant Permission / Rescan'),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (errorMessage != null && folders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: cs.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load folders',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
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
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (folders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open,
                size: 72,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No folders detected',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Once scanning completes, your video folders will appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final String sortLabel = () {
      switch (_sortMode) {
        case _FolderSortMode.name:
          return 'Name (A–Z)';
        case _FolderSortMode.count:
          return 'Video count (high to low)';
        case _FolderSortMode.size:
          return 'Size (largest first)';
      }
    }();

    return Column(
      children: [
        Material(
          color: cs.surface,
          elevation: 1,
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Folders',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${folders.length} folder${folders.length == 1 ? '' : 's'} • $sortLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha:0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tip: Long press a folder to hide or unhide it.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_FolderSortMode>(
                  tooltip: 'Sort folders',
                  icon: const Icon(Icons.sort_rounded),
                  onSelected: _setSortMode,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _FolderSortMode.name,
                      child: Text('Name (A–Z)'),
                    ),
                    PopupMenuItem(
                      value: _FolderSortMode.count,
                      child: Text('Video count (high → low)'),
                    ),
                    PopupMenuItem(
                      value: _FolderSortMode.size,
                      child: Text('Size (largest first)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return YSFolderListTile(
                folder: folder,
                onTap: () => _openFolder(folder),
                onLongPress: () => _onLongPressFolder(folder),
              );
            },
          ),
        ),
      ],
    );
  }
}
