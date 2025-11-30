// lib/shared/telemetry/telemetry_local_store.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../services/log_service.dart';
import 'event_envelope.dart';

const String _kTelemetryEventsKey = 'ys_telemetry_events_v1';

class TelemetryLocalStore {
  TelemetryLocalStore._internal();
  static final TelemetryLocalStore instance = TelemetryLocalStore._internal();

  final List<EventEnvelope> _buffer = <EventEnvelope>[];

  List<EventEnvelope> get buffer =>
      List<EventEnvelope>.unmodifiable(_buffer);

  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kTelemetryEventsKey);
      if (list == null) return;

      _buffer.clear();
      for (final json in list) {
        try {
          _buffer.add(EventEnvelope.fromJson(json));
        } catch (_) {}
      }
    } catch (e, st) {
      LogService.instance
          .logError('[TelemetryLocalStore] loadFromDisk error: $e', st);
    }
  }

  Future<void> persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _buffer.map((e) => e.toJson()).toList();
      await prefs.setStringList(_kTelemetryEventsKey, list);
    } catch (e, st) {
      LogService.instance
          .logError('[TelemetryLocalStore] persist error: $e', st);
    }
  }

  Future<void> add(EventEnvelope e) async {
    _buffer.add(e);
    await persist();
  }

  Future<List<EventEnvelope>> drain() async {
    final list = List<EventEnvelope>.from(_buffer);
    _buffer.clear();
    await persist();
    return list;
  }

  Future<void> purgeOlderThan(Duration age) async {
    final threshold = DateTime.now().subtract(age);
    _buffer.removeWhere((e) => e.timestamp.isBefore(threshold));
    await persist();
  }

  Future<void> clearAll() async {
    _buffer.clear();
    await persist();
  }
}
