import 'dart:convert';

/// EventEnvelope
/// =============
/// Typed container for all telemetry events.
class EventEnvelope {
  final String eventName;
  final DateTime timestamp;
  final String? userId;
  final String sessionId;
  final Map<String, dynamic> properties;
  final String platform;
  final String appVersion;
  final String osVersion;
  final String deviceModel;
  final double? samplingRate;

  EventEnvelope({
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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

  String toJson() => jsonEncode(toMap());

  factory EventEnvelope.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return EventEnvelope(
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
}
