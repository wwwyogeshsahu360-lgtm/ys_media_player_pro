// lib/features/cast/domain/cast_device.dart
import 'package:equatable/equatable.dart';

/// A generic "cast" capable device (Chromecast, Smart TV, etc.).
class CastDevice extends Equatable {
  final String id;
  final String name;
  final String ip;
  final String type; // e.g. "chromecast", "dlna", "mock"

  /// Whether this device can play video content.
  final bool supportsVideo;

  /// Whether this device can play audio-only content.
  final bool supportsAudio;

  const CastDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.type,
    this.supportsVideo = true,
    this.supportsAudio = true,
  });

  @override
  List<Object?> get props => <Object?>[id, name, ip, type];

  CastDevice copyWith({
    String? id,
    String? name,
    String? ip,
    String? type,
    bool? supportsVideo,
    bool? supportsAudio,
  }) {
    return CastDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      type: type ?? this.type,
      supportsVideo: supportsVideo ?? this.supportsVideo,
      supportsAudio: supportsAudio ?? this.supportsAudio,
    );
  }

  @override
  String toString() =>
      'CastDevice(id=$id, name=$name, ip=$ip, type=$type, video=$supportsVideo, audio=$supportsAudio)';
}
