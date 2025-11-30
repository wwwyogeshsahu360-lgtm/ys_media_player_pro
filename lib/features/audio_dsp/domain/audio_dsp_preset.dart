import 'dart:convert';

class AudioDspPreset {
  final String id;
  final String name;
  final List<double> bandGains;
  final double bassBoost;
  final double virtualizer;
  final double reverb;
  final bool limiterEnabled;
  final DateTime createdAt;

  AudioDspPreset({
    required this.id,
    required this.name,
    required this.bandGains,
    required this.bassBoost,
    required this.virtualizer,
    required this.reverb,
    required this.limiterEnabled,
    required this.createdAt,
  });

  /// ---------------------------------------------------------------
  /// DEFAULT FREQUENCY LABELS
  /// ---------------------------------------------------------------
  static const List<String> defaultFrequencies = [
    "31 Hz",
    "62 Hz",
    "125 Hz",
    "250 Hz",
    "500 Hz",
    "1 kHz",
    "2 kHz",
    "4 kHz",
    "8 kHz",
    "16 kHz",
  ];

  /// ---------------------------------------------------------------
  /// DEFAULT PRESET  **(THIS WAS MISSING IN YOUR PROJECT)**
  /// ---------------------------------------------------------------
  static AudioDspPreset defaultPreset() {
    return AudioDspPreset(
      id: "default",
      name: "Default",
      bandGains: List<double>.filled(10, 0.0),
      bassBoost: 0.0,
      virtualizer: 0.0,
      reverb: 0.0,
      limiterEnabled: false,
      createdAt: DateTime.now(),
    );
  }

  /// ---------------------------------------------------------------
  /// COPYWITH → required for eq_screen imports
  /// ---------------------------------------------------------------
  AudioDspPreset copyWith({
    String? id,
    String? name,
    List<double>? bandGains,
    double? bassBoost,
    double? virtualizer,
    double? reverb,
    bool? limiterEnabled,
    DateTime? createdAt,
  }) {
    return AudioDspPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      bandGains: bandGains ?? List<double>.from(this.bandGains),
      bassBoost: bassBoost ?? this.bassBoost,
      virtualizer: virtualizer ?? this.virtualizer,
      reverb: reverb ?? this.reverb,
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// ---------------------------------------------------------------
  /// EXPORT WITH CHECKSUM
  /// ---------------------------------------------------------------
  String exportWithChecksum() {
    final Map<String, dynamic> data = {
      "id": id,
      "name": name,
      "bandGains": bandGains,
      "bassBoost": bassBoost,
      "virtualizer": virtualizer,
      "reverb": reverb,
      "limiterEnabled": limiterEnabled,
      "createdAt": createdAt.toIso8601String(),
    };

    final String jsonStr = jsonEncode(data);
    final String checksum =
    base64Encode(utf8.encode(jsonStr)).substring(0, 16);

    return jsonEncode({
      "data": data,
      "checksum": checksum,
    });
  }

  /// ---------------------------------------------------------------
  /// FROM JSON
  /// ---------------------------------------------------------------
  static AudioDspPreset fromJson(Map<String, dynamic> map) {
    return AudioDspPreset(
      id: map["id"],
      name: map["name"],
      bandGains: (map["bandGains"] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      bassBoost: (map["bassBoost"] as num).toDouble(),
      virtualizer: (map["virtualizer"] as num).toDouble(),
      reverb: (map["reverb"] as num).toDouble(),
      limiterEnabled: map["limiterEnabled"],
      createdAt: DateTime.parse(map["createdAt"]),
    );
  }
  /// ---------------------------------------------------------------
  /// TO JSON  (for preset store)
  /// ---------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "bandGains": bandGains,
      "bassBoost": bassBoost,
      "virtualizer": virtualizer,
      "reverb": reverb,
      "limiterEnabled": limiterEnabled,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  /// ---------------------------------------------------------------
  /// IMPORT/EXPORT helper
  /// ---------------------------------------------------------------
  static AudioDspPreset importFromExport(String jsonStr) {
    final Map<String, dynamic> outer = jsonDecode(jsonStr);
    final Map<String, dynamic> data = outer["data"];
    return AudioDspPreset.fromJson(data);
  }

}
