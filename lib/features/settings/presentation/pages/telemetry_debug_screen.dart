// lib/features/settings/presentation/pages/telemetry_debug_screen.dart
import 'package:flutter/material.dart';

import '../../../../shared/telemetry/telemetry_service.dart';
import '../../../../shared/services/log_service.dart';

/// Telemetry Debug Screen
/// ======================
/// Debug-only UI to inspect telemetry buffer & force flush.
class TelemetryDebugScreen extends StatefulWidget {
  const TelemetryDebugScreen({super.key});

  @override
  State<TelemetryDebugScreen> createState() => _TelemetryDebugScreenState();
}

class _TelemetryDebugScreenState extends State<TelemetryDebugScreen> {
  final TelemetryService _telemetry = TelemetryService.instance;
  final LogService _log = LogService.instance;

  bool _loading = false;
  List<Map<String, dynamic>> _events = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // -------------------------------
  // FETCH BUFFERED EVENTS
  // -------------------------------
  Future<void> _loadEvents() async {
    setState(() => _loading = true);

    try {
      final List<Map<String, dynamic>> data =
      await _telemetry.getBufferedEvents();
      if (!mounted) return;
      setState(() => _events = data);
    } catch (e, st) {
      _log.logError('[TelemetryDebug] Load error: $e', st);
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // -------------------------------
  // FLUSH TELEMETRY
  // -------------------------------
  Future<void> _flush() async {
    setState(() => _loading = true);

    try {
      await _telemetry.flushBuffer();
      await _loadEvents();
    } catch (e, st) {
      _log.logError('[TelemetryDebug] Flush error: $e', st);
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // -------------------------------
  // CLEAR TELEMETRY
  // -------------------------------
  Future<void> _clear() async {
    setState(() => _loading = true);

    try {
      await _telemetry.clearBuffer();
      await _loadEvents();
    } catch (e, st) {
      _log.logError('[TelemetryDebug] Clear error: $e', st);
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // -------------------------------
  // UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Telemetry Debug')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Flush Now'),
                  onPressed: _flush,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Clear Buffer'),
                  onPressed: _clear,
                ),
              ],
            ),
          ),
          Expanded(
            child: _events.isEmpty
                ? const Center(child: Text('No telemetry data.'))
                : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (_, int i) {
                final Map<String, dynamic> e = _events[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      e.toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
