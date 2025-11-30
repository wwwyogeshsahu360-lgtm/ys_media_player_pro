// lib/shared/telemetry/telemetry_backend.dart
import 'event_envelope.dart';
import '../services/log_service.dart';

abstract class TelemetryBackend {
  Future<void> sendBatch(List<EventEnvelope> events);
}

class MockTelemetryBackend extends TelemetryBackend {
  MockTelemetryBackend._internal();
  static final MockTelemetryBackend instance =
  MockTelemetryBackend._internal();

  @override
  Future<void> sendBatch(List<EventEnvelope> events) async {
    final log = LogService.instance;
    log.log('[Telemetry] Sending batch of ${events.length} events');

    for (final e in events) {
      log.log('[Telemetry] ${e.eventName} ${e.properties}');
    }

    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
