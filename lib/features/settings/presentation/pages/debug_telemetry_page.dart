// lib/features/settings/presentation/pages/debug_telemetry_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../shared/telemetry/telemetry_service.dart';
import '../../../../shared/telemetry/feature_flag_service.dart';
import '../../../../shared/telemetry/feedback_service.dart';

/// DebugTelemetryPage
/// ==================
/// Visible only in debug builds or when a dev flag is enabled.
class DebugTelemetryPage extends StatelessWidget {
  const DebugTelemetryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final events = TelemetryService.instance.debugSnapshot();
    final flags = FeatureFlagService.instance.dumpFlags();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry Debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Text(
            'Buffered events: ${events.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const Text('No buffered events.')
          else
            ...events.take(30).map(
                  (e) => Card(
                child: ListTile(
                  dense: true,
                  title: Text(e.eventName),
                  subtitle: Text(
                    '${e.timestamp.toIso8601String()}\n${e.properties}',
                  ),
                ),
              ),
            ),
          const Divider(),
          Text(
            'Feature Flags',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(flags.toString()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await TelemetryService.instance.flush();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flush requested')),
                );
              }
            },
            child: const Text('Force flush now'),
          ),
          const SizedBox(height: 8),
          if (kDebugMode)
            ElevatedButton(
              onPressed: () async {
                final feedbacks =
                await FeedbackService.instance.readAll();
                if (context.mounted) {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Feedback entries'),
                      content: SingleChildScrollView(
                        child: Text(
                          feedbacks
                              .map(
                                (FeedbackEntry f) =>
                            '${f.createdAt.toIso8601String()}: ${f.message}',
                          )
                              .join('\n\n'),
                        ),
                      ),
                    ),
                  );
                }
              },
              child: const Text('View feedback entries (debug)'),
            ),
        ],
      ),
    );
  }
}
