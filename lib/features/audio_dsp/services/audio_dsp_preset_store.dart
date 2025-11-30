// lib/features/audio_dsp/services/audio_dsp_preset_store.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/audio_dsp_preset.dart';

/// Stores custom DSP presets locally.
///
/// Built-in presets are created in code and not persisted; only custom presets
/// are stored here.
class AudioDspPresetStore {
  static const String _kPrefsKey = 'audio_dsp_custom_presets_v1';

  Future<List<AudioDspPreset>> loadCustomPresets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_kPrefsKey);
    if (jsonStr == null || jsonStr.isEmpty) return <AudioDspPreset>[];
    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((dynamic v) =>
          AudioDspPreset.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <AudioDspPreset>[];
    }
  }

  Future<void> saveCustomPresets(List<AudioDspPreset> presets) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(
      presets.map((AudioDspPreset p) => p.toJson()).toList(),
    );
    await prefs.setString(_kPrefsKey, jsonStr);
  }

  Future<void> upsertPreset(AudioDspPreset preset) async {
    final List<AudioDspPreset> current = await loadCustomPresets();
    final int idx = current.indexWhere((AudioDspPreset p) => p.id == preset.id);
    if (idx >= 0) {
      current[idx] = preset;
    } else {
      current.add(preset);
    }
    await saveCustomPresets(current);
  }

  Future<void> deletePreset(String id) async {
    final List<AudioDspPreset> current = await loadCustomPresets();
    current.removeWhere((AudioDspPreset p) => p.id == id);
    await saveCustomPresets(current);
  }
}
