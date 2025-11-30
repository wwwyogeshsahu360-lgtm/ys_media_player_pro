// lib/shared/telemetry/telemetry_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:package_info_plus/package_info_plus.dart';

import '../services/consent_service.dart';
import '../services/log_service.dart';
import '../services/uuid_service.dart';
import 'event_envelope.dart';
import 'telemetry_backend.dart';
import 'telemetry_local_store.dart';

/// TelemetryService
/// ================
/// Privacy-first analytics with local buffering & consent gate.
class TelemetryService {
  TelemetryService._internal();
  static final TelemetryService instance = TelemetryService._internal();

  final TelemetryLocalStore _store = TelemetryLocalStore.instance;
  final TelemetryBackend _backend = MockTelemetryBackend.instance;
  final LogService _log = LogService.instance;

  bool _initialized = false;
  String _sessionId = '';
  String _platform = '';
  String _appVersion = '';
  String _osVersion = '';
  String _deviceModel = 'unknown';

  Timer? _flushTimer;
  int _consecutiveFailures = 0;

  static const int _kMaxBufferBeforeFlush = 30;
  static const Duration _kFlushInterval = Duration(seconds: 30);
  static const Duration _kRetention = Duration(days: 7);

  /// INIT ----------------------------------------------------------------------
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _sessionId = UuidService.instance.generateSessionId();
    _platform = Platform.operatingSystem;

    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersion = 'unknown';
    }

    _osVersion = _platform;

    await _store.loadFromDisk();
    await _store.purgeOlderThan(_kRetention);

    _startFlushTimer();
    _log.log('[TelemetryService] Initialized. Session=$_sessionId');
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_kFlushInterval, (_) => flush());
  }

  /// TRACK EVENT ---------------------------------------------------------------
  Future<void> trackEvent(
      String name,
      Map<String, dynamic> props, {
        double? sampling,
      }) async {
    final consent = ConsentService.instance;
    await consent.init();

    if (!consent.telemetryEnabled) return;

    // sampling
    if (sampling != null && sampling > 0 && sampling < 1) {
      if (Random().nextDouble() > sampling) return;
    }

    final sanitized = _sanitizeProperties(props);

    final event = EventEnvelope(
      eventName: name,
      timestamp: DateTime.now(),
      sessionId: _sessionId,
      properties: sanitized,
      platform: _platform,
      appVersion: _appVersion,
      osVersion: _osVersion,
      deviceModel: _deviceModel,
      samplingRate: sampling,
    );

    await _store.add(event);

    if (_store.buffer.length >= _kMaxBufferBeforeFlush) {
      unawaited(flush());
    }
  }

  Map<String, dynamic> _sanitizeProperties(Map<String, dynamic> input) {
    final out = <String, dynamic>{};

    final emailRe = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
    final phoneRe = RegExp(r'\+?\d{7,}');
    final pathRe = RegExp(r'[A-Za-z]:[\\/]|\/[A-Za-z0-9_]');

    input.forEach((key, value) {
      if (value is String) {
        var v = value;
        if (emailRe.hasMatch(v)) v = '<redacted_email>';
        if (phoneRe.hasMatch(v)) v = '<redacted_phone>';
        if (pathRe.hasMatch(v)) v = '<redacted_path>';
        out[key] = v;
      } else if (value is num || value is bool || value == null) {
        out[key] = value;
      } else {
        out[key] = value.toString();
      }
    });

    return out;
  }

  /// FLUSH ---------------------------------------------------------------------
  Future<void> flush() async {
    final consent = ConsentService.instance;
    await consent.init();

    if (!consent.telemetryEnabled) return;
    if (_store.buffer.isEmpty) return;

    final events = await _store.drain();
    if (events.isEmpty) return;

    try {
      await _backend.sendBatch(events);
      _consecutiveFailures = 0;
    } catch (e, st) {
      _consecutiveFailures++;
      _log.logError('[TelemetryService] flush error: $e', st);

      // put back events
      for (final ev in events) {
        await _store.add(ev);
      }

      final int backoffSec =
      min<int>(60, pow(2, _consecutiveFailures).toInt());

      _flushTimer?.cancel();
      _flushTimer = Timer(
        Duration(seconds: backoffSec),
        _startFlushTimer,
      );
    }
  }

  Future<void> purgeAll() => _store.clearAll();

  /// DEBUG HELPERS -------------------------------------------------------------
  List<EventEnvelope> debugSnapshot() =>
      List<EventEnvelope>.unmodifiable(_store.buffer);

  Future<List<Map<String, dynamic>>> getBufferedEvents() async {
    return _store.buffer.map(_eventToMap).toList(growable: false);
  }

  Future<void> flushBuffer() => flush();
  Future<void> clearBuffer() => _store.clearAll();

  Map<String, dynamic> _eventToMap(EventEnvelope e) {
    return {
      'eventName': e.eventName,
      'timestamp': e.timestamp.toIso8601String(),
      'sessionId': e.sessionId,
      'properties': e.properties,
      'platform': e.platform,
      'appVersion': e.appVersion,
      'osVersion': e.osVersion,
      'deviceModel': e.deviceModel,
      'samplingRate': e.samplingRate,
    };
  }
}
