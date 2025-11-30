// lib/shared/cloud/cloud_sync_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/log_service.dart';

/// Mock cloud sync service.
///
/// This does NOT talk to any real backend.
/// Instead, it simulates latency and "remote storage" in local prefs
/// so that your UI flow can be built & tested safely.
class CloudSyncService {
  CloudSyncService._internal();

  static final CloudSyncService instance = CloudSyncService._internal();

  final LogService _log = LogService.instance;

  static const String _kRemotePrefsKey = 'ys_cloud_mock_prefs';
  static const String _kRemoteMetaKey = 'ys_cloud_mock_meta';
  static const String _kLastSyncKey = 'ys_cloud_last_sync';

  DateTime? _lastSyncTime;
  bool _syncInProgress = false;

  DateTime? get lastSyncTime => _lastSyncTime;

  bool get syncInProgress => _syncInProgress;

  Future<Map<String, dynamic>> fetchPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_kRemotePrefsKey);
    if (jsonStr == null) return <String, dynamic>{};
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  Future<void> syncPreferences(Map<String, dynamic> prefsMap) async {
    _syncInProgress = true;
    _log.log('[CloudSyncService] syncPreferences started');
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRemotePrefsKey, jsonEncode(prefsMap));
    _lastSyncTime = DateTime.now();
    await prefs.setInt(_kLastSyncKey, _lastSyncTime!.millisecondsSinceEpoch);

    _syncInProgress = false;
    _log.log('[CloudSyncService] syncPreferences completed');
  }

  Future<Map<String, dynamic>> fetchSmallMetadata(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('$_kRemoteMetaKey.$userId');
    if (jsonStr == null) return <String, dynamic>{};
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  Future<void> syncSmallMetadata(
      String userId,
      Map<String, dynamic> meta,
      ) async {
    _syncInProgress = true;
    _log.log('[CloudSyncService] syncSmallMetadata started for $userId');
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kRemoteMetaKey.$userId', jsonEncode(meta));
    _lastSyncTime = DateTime.now();
    await prefs.setInt(_kLastSyncKey, _lastSyncTime!.millisecondsSinceEpoch);

    _syncInProgress = false;
    _log.log('[CloudSyncService] syncSmallMetadata completed');
  }

  Future<void> loadLastSyncTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? ts = prefs.getInt(_kLastSyncKey);
    if (ts != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(ts);
    }
  }
}
