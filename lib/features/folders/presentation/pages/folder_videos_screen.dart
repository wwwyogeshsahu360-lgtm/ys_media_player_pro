import 'package:flutter/material.dart';

import '../../../../shared/controllers/library_controller.dart';
import '../../../../shared/models/folder_item.dart';
import '../../../../shared/models/media_item.dart';
import '../../../../shared/widgets/ys_video_list_tile.dart';

/// FolderVideosScreen
/// ===================
/// Displays all videos inside a particular folder, with search and sort
/// similar to VideosTab but scoped to a single folder.
class FolderVideosScreen extends StatefulWidget {
  const FolderVideosScreen({
    super.key,
    required this.folder,
    required this.controller,
  });

  final FolderItem folder;
  final LibraryController controller;

  @override
  State<FolderVideosScreen> createState() => _FolderVideosScreenState();
}

enum _FolderVideoSortMode { title, dateAdded, duration }

class _FolderVideosScreenState extends State<FolderVideosScreen> {
  _FolderVideoSortMode _sortMode = _FolderVideoSortMode.dateAdded;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MediaItem> _getFolderVideos() {
    final String folderPath = widget.folder.path;
    final List<MediaItem> all = widget.controller.videos
        .where((m) => m.folderPath == folderPath)
        .toList();

    // Apply search
    List<MediaItem> result = all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (m) => m.fileName.toLowerCase().contains(q),
      )
          .toList();
    }

    // Apply sort
    result.sort((a, b) {
      switch (_sortMode) {
        case _FolderVideoSortMode.title:
          return a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase());
        case _FolderVideoSortMode.dateAdded:
          return b.dateAdded.compareTo(a.dateAdded);
        case _FolderVideoSortMode.duration:
          return b.duration.inMilliseconds.compareTo(
            a.duration.inMilliseconds,
          );
      }
    });

    return result;
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  void _setSortMode(_FolderVideoSortMode mode) {
    setState(() {
      _sortMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videos = _getFolderVideos();

    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar
            ? TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search in this folder...',
            border: InputBorder.none,
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.folder.name),
            Text(
              '${videos.length} video${videos.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _showSearchBar ? 'Close search' : 'Search',
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: _toggleSearchBar,
          ),
          PopupMenuButton<_FolderVideoSortMode>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            onSelected: _setSortMode,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _FolderVideoSortMode.title,
                child: Text('Title (A–Z)'),
              ),
              PopupMenuItem(
                value: _FolderVideoSortMode.dateAdded,
                child: Text('Date added (newest first)'),
              ),
              PopupMenuItem(
                value: _FolderVideoSortMode.duration,
                child: Text('Duration (longest first)'),
              ),
            ],
          ),
        ],
      ),
      body: videos.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No videos found in this folder.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = videos[index];
          return YSVideoListTile(
            item: item,
            onTap: () {
              // Future: open player for this video.
            },
          );
        },
      ),
    );
  }
}
