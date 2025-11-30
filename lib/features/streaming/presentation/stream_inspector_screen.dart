// lib/features/streaming/presentation/stream_inspector_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../streaming_facade.dart';
import '../domain/stream_manifest.dart';
import '../domain/streamer_event.dart';
import '../domain/adaptive_stream_session.dart';

/// StreamInspectorScreen
/// ---------------------
/// Debug-only UI to inspect streaming manifest and events.
/// This is safe to keep in release; it does nothing unless opened.
class StreamInspectorScreen extends StatefulWidget {
  const StreamInspectorScreen({super.key});

  @override
  State<StreamInspectorScreen> createState() => _StreamInspectorScreenState();
}

class _StreamInspectorScreenState extends State<StreamInspectorScreen> {
  final StreamingFacade _facade = StreamingFacade.instance;

  final TextEditingController _urlController = TextEditingController(
    text:
    'https://example.com/mock/master.m3u8', // just a sample string, no real request
  );

  StreamManifest? _manifest;
  AdaptiveStreamSession? _session;
  final List<StreamerEvent> _events = <StreamerEvent>[];

  StreamSubscription<StreamerEvent>? _sub;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = _facade.streamer.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  void _onEvent(StreamerEvent e) {
    setState(() {
      _events.insert(0, e);
      if (_events.length > 50) {
        _events.removeLast();
      }
      if (e is SessionOpenedEvent) {
        _session = e.session;
      }
    });
  }

  Future<void> _loadManifest() async {
    setState(() {
      _loading = true;
      _error = null;
      _manifest = null;
      _session = null;
      _events.clear();
    });

    try {
      final String url = _urlController.text.trim();
      final manifest = await _facade.streamer.loadManifest(url);
      setState(() => _manifest = manifest);
    } catch (e) {
      setState(() => _error = e.toString());
    }

    setState(() => _loading = false);
  }

  Future<void> _openSession() async {
    final manifest = _manifest;
    if (manifest == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _facade.streamer.openSession(manifest, _facade.defaultPolicy);
    } catch (e) {
      setState(() => _error = e.toString());
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Inspector (Mock)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Stream URL (HLS .m3u8 / DASH .mpd / any)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: _loading ? null : _loadManifest,
                  child: const Text('Load Manifest'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                  _loading || _manifest == null ? null : _openSession,
                  child: const Text('Open Session'),
                ),
              ],
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: _buildManifestPanel(theme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _buildEventsPanel(theme),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManifestPanel(ThemeData theme) {
    final manifest = _manifest;
    final session = _session;

    if (manifest == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('No manifest loaded'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Text(
            'Type: ${manifest.type}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text('Video tracks: ${manifest.video.length}'),
          Text('Audio tracks: ${manifest.audio.length}'),
          Text('Subtitle tracks: ${manifest.subtitles.length}'),
          const Divider(),
          if (session != null) ...<Widget>[
            Text(
              'Current representation:',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              '${session.currentRepresentation.id} '
                  '(${session.currentRepresentation.width}x'
                  '${session.currentRepresentation.height}, '
                  '${session.currentRepresentation.bandwidth} bps)',
            ),
            const Divider(),
          ],
          Text(
            'Video Representations:',
            style: theme.textTheme.titleSmall,
          ),
          for (final v in manifest.video)
            Text(
              '- ${v.id}: ${v.width}x${v.height}, ${v.bandwidth} bps',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildEventsPanel(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _events.length,
        itemBuilder: (BuildContext context, int index) {
          final e = _events[index];
          return ListTile(
            dense: true,
            title: Text(e.runtimeType.toString()),
            subtitle: Text(e.toString()),
          );
        },
      ),
    );
  }
}
