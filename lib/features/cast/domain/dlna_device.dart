// lib/features/cast/domain/dlna_device.dart
import 'package:equatable/equatable.dart';

/// Basic model for a DLNA / UPnP device on local network.
class DlnaDevice extends Equatable {
  final String id;
  final String friendlyName;
  final String ip;
  final Uri controlUrl;

  const DlnaDevice({
    required this.id,
    required this.friendlyName,
    required this.ip,
    required this.controlUrl,
  });

  @override
  List<Object?> get props => <Object?>[id, friendlyName, ip, controlUrl];

  @override
  String toString() =>
      'DlnaDevice(id=$id, name=$friendlyName, ip=$ip, control=$controlUrl)';
}
