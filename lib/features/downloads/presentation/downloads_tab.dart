// lib/features/downloads/presentation/downloads_tab.dart
import 'package:flutter/material.dart';

import '../data/download_manager.dart';
import '../domain/download_item.dart';
import '../domain/download_status.dart';

class DownloadsTab extends StatefulWidget {
  const DownloadsTab({super.key});

  @override
  State<DownloadsTab> createState() => _DownloadsTabState();
}

class _DownloadsTabState extends State<DownloadsTab> {
  @override
  void initState() {
    super.initState();
    DownloadManager.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return StreamBuilder<List<DownloadItem>>(
      stream: DownloadManager.instance.downloadsStream,
      initialData: DownloadManager.instance.currentDownloads,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <DownloadItem>[];

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_outlined, size: 72, color: cs.primary),
                  const SizedBox(height: 16),
                  Text(
                    'No downloads yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start downloads from online videos to see them here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return _DownloadListTile(item: item);
          },
        );
      },
    );
  }
}

class _DownloadListTile extends StatelessWidget {
  const _DownloadListTile({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final percent =
    item.totalBytes != null && item.totalBytes! > 0 ? (item.progress * 100) : 0.0;

    return ListTile(
      leading: Icon(
        item.status == DownloadStatus.completed
            ? Icons.check_circle_rounded
            : Icons.download_rounded,
        color: item.status == DownloadStatus.completed
            ? cs.primary
            : cs.onSurfaceVariant,
      ),
      title: Text(
        item.filePath?.split('/').last ?? item.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.status.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85),
            ),
          ),
          if (item.status == DownloadStatus.downloading ||
              item.status == DownloadStatus.queued ||
              item.status == DownloadStatus.paused) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: item.totalBytes != null ? item.progress.clamp(0.0, 1.0) : null,
            ),
            const SizedBox(height: 2),
            if (item.totalBytes != null)
              Text(
                '${percent.toStringAsFixed(1)} %',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ],
      ),
      trailing: _buildActions(context, item),
    );
  }

  Widget _buildActions(BuildContext context, DownloadItem item) {
    final dm = DownloadManager.instance;

    if (item.status == DownloadStatus.completed) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'delete':
              dm.removeDownload(item.id);
              break;
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.status == DownloadStatus.downloading)
          IconButton(
            tooltip: 'Pause',
            icon: const Icon(Icons.pause_rounded),
            onPressed: () => dm.pauseDownload(item.id),
          )
        else if (item.status == DownloadStatus.paused ||
            item.status == DownloadStatus.failed ||
            item.status == DownloadStatus.queued)
          IconButton(
            tooltip: 'Resume',
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: () => dm.resumeDownload(item.id),
          ),
        IconButton(
          tooltip: 'Cancel',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => dm.cancelDownload(item.id),
        ),
      ],
    );
  }
}
