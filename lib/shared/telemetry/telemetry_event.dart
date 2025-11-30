import 'dart:convert';

/// TelemetryEventEnvelope
/// ======================
/// Strongly typed analytics event used by TelemetryService.
///
/// All fields are JSON-safe.
class TelemetryEventEnvelope {
  TelemetryEventEnvelope({
    required this.id,
    required this.eventName,
    required this.timestamp,
    required this.sessionId,
    required this.properties,
    required this.platform,
    required this.appVersion,
    required this.osVersion,
    required this.deviceModel,
    this.userId,
    this.samplingRate,
  });

  final String id;
  final String eventName;
  final DateTime timestamp;
  final String sessionId;
  final Map<String, dynamic> properties;
  final String platform;
  final String appVersion;
  final String osVersion;
  final String deviceModel;
  final String? userId;
  final double? samplingRate;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'eventName': eventName,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
      'properties': properties,
      'platform': platform,
      'appVersion': appVersion,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
      'samplingRate': samplingRate,
    };
  }

  factory TelemetryEventEnvelope.fromMap(Map<String, dynamic> map) {
    return TelemetryEventEnvelope(
      id: map['id'] as String,
      eventName: map['eventName'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      userId: map['userId'] as String?,
      sessionId: map['sessionId'] as String,
      properties: (map['properties'] as Map).cast<String, dynamic>(),
      platform: map['platform'] as String,
      appVersion: map['appVersion'] as String,
      osVersion: map['osVersion'] as String,
      deviceModel: map['deviceModel'] as String,
      samplingRate: (map['samplingRate'] as num?)?.toDouble(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TelemetryEventEnvelope.fromJson(String source) =>
      TelemetryEventEnvelope.fromMap(
        jsonDecode(source) as Map<String, dynamic>,
      );
}
