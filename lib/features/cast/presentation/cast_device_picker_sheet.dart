// lib/features/cast/presentation/cast_device_picker_sheet.dart
import 'package:flutter/material.dart';

import '../cast_manager.dart';
import '../domain/cast_device.dart';
import '../../../shared/models/media_item.dart';

/// Shows a bottom sheet listing available cast / DLNA devices.
///
/// When a device is tapped, the sheet will call [CastManager.connectAndPlay]
/// for the provided [mediaItem].
Future<void> showCastDevicePickerSheet(
    BuildContext context, {
      MediaItem? mediaItem,
    }) async {
  final CastManager manager = CastManager.instance;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      final ThemeData theme = Theme.of(context);
      final ColorScheme cs = theme.colorScheme;

      return StreamBuilder<List<CastDevice>>(
        stream: manager.devicesStream,
        builder: (BuildContext context, AsyncSnapshot<List<CastDevice>> snap) {
          final List<CastDevice> devices = snap.data ?? <CastDevice>[];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.cast_rounded, color: cs.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Play on device',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Searching for devices on your network...',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: devices.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 40),
                      itemBuilder: (BuildContext context, int index) {
                        final CastDevice d = devices[index];
                        return ListTile(
                          leading: Icon(
                            d.type.startsWith('dlna')
                                ? Icons.speaker_group
                                : Icons.tv_rounded,
                          ),
                          title: Text(d.name),
                          subtitle: Text('${d.type} • ${d.ip}'),
                          onTap: mediaItem == null
                              ? null
                              : () async {
                            await manager.connectAndPlay(d, mediaItem);
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).maybePop();
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Mock devices only for now. Later you can plug real Chromecast/DLNA providers.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                    theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
