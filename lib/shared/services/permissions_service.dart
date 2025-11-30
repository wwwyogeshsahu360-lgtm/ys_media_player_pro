import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'log_service.dart';
import 'package:ys_media_player_pro/core/errors/media_permission_exception.dart';

/// PermissionsService
/// ==================
/// Centralized wrapper around permission_handler to manage media-related
/// permissions in a device-agnostic way.
///
/// - On Android: requests storage/videos permissions.
/// - On iOS: requests photo library permissions.
/// - On web/unsupported platforms: returns false gracefully.
class PermissionsService {
  PermissionsService._internal();

  static final PermissionsService instance = PermissionsService._internal();

  /// Returns true if media permission is already granted.
  Future<bool> hasMediaPermission() async {
    if (kIsWeb) {
      // For simplicity, treat web as unsupported for local media scan.
      return false;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    final permissions = _platformMediaPermissions();
    if (permissions.isEmpty) {
      return false;
    }

    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }
    }

    return false;
  }

  /// Ensures that media permission is granted. If not, it will request
  /// the relevant permissions. Returns:
  ///
  /// - true  → permission granted
  /// - false → user denied (non-permanently) or unsupported platform
  ///
  /// Throws [MediaPermissionException] if permission is permanently denied.
  Future<bool> ensureMediaPermissionGranted() async {
    if (await hasMediaPermission()) {
      return true;
    }

    if (kIsWeb) {
      LogService.instance.log(
        'PermissionsService: media permission not applicable on web',
      );
      return false;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      LogService.instance.log(
        'PermissionsService: media permission unsupported on this platform',
      );
      return false;
    }

    final permissions = _platformMediaPermissions();
    if (permissions.isEmpty) {
      LogService.instance.log(
        'PermissionsService: no applicable media permissions for platform',
      );
      return false;
    }

    final Map<Permission, PermissionStatus> statusMap =
    await permissions.request();

    bool anyGranted = false;
    bool anyPermanentlyDenied = false;

    for (final entry in statusMap.entries) {
      final status = entry.value;
      if (status.isGranted || status.isLimited) {
        anyGranted = true;
      } else if (status.isPermanentlyDenied) {
        anyPermanentlyDenied = true;
      }
    }

    if (anyGranted) {
      LogService.instance.log('PermissionsService: media permission granted');
      return true;
    }

    if (anyPermanentlyDenied) {
      const msg =
          'Media access permission is permanently denied. Please enable it '
          'from system settings to scan your videos.';
      LogService.instance.logError(
        'PermissionsService: $msg',
        StackTrace.current,
      );
      throw const MediaPermissionException(msg);
    }

    const msg = 'Media access permission was denied by the user.';
    LogService.instance.log('PermissionsService: $msg');
    return false;
  }

  /// Returns the list of permissions required for media access on the
  /// current platform.
  List<Permission> _platformMediaPermissions() {
    if (kIsWeb) {
      return const <Permission>[];
    }

    if (Platform.isAndroid) {
      // permission_handler defines `videos` for Android 13+ along with storage.
      return <Permission>[
        Permission.videos,
        Permission.storage,
      ];
    }

    if (Platform.isIOS) {
      return <Permission>[
        Permission.photos,
      ];
    }

    return const <Permission>[];
  }
}
