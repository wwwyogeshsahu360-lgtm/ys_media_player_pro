/// MediaPermissionException
/// ========================
/// Thrown when media-related permissions (storage, photos, videos, etc.)
/// are denied or permanently denied by the user. This allows the
/// repository/controller to distinguish between generic errors and
/// permission-specific issues and update the UI accordingly.
class MediaPermissionException implements Exception {
  final String message;

  const MediaPermissionException(this.message);

  @override
  String toString() => 'MediaPermissionException: $message';
}
