// lib/features/audio_dsp/services/audio_profile_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Maps device IDs (e.g. Bluetooth address, cast device id) to preset IDs.
///
/// This intentionally does not know about the preset details – only the
/// mapping. Higher layers look up the actual preset via AudioDspPresetStore.
class AudioProfileService {
  static const String _kPrefsKey = 'audio_dsp_device_profiles_v1';

  Future<Map<String, String>> _loadRaw() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_kPrefsKey);
    if (jsonStr == null || jsonStr.isEmpty) return <String, String>{};
    try {
      final Map<String, dynamic> map =
      jsonDecode(jsonStr) as Map<String, dynamic>;
      return map.map(
            (String k, dynamic v) => MapEntry<String, String>(k, v as String),
      );
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> _saveRaw(Map<String, String> map) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(map));
  }

  Future<String?> getPresetIdForDevice(String deviceId) async {
    final Map<String, String> map = await _loadRaw();
    return map[deviceId];
  }

  Future<void> setPresetIdForDevice(String deviceId, String presetId) async {
    final Map<String, String> map = await _loadRaw();
    map[deviceId] = presetId;
    await _saveRaw(map);
  }

  Future<void> clearDevice(String deviceId) async {
    final Map<String, String> map = await _loadRaw();
    map.remove(deviceId);
    await _saveRaw(map);
  }
}
