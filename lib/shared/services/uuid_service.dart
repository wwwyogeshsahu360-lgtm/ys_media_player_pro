import 'dart:math';

/// UuidService
/// ===========
/// Simple random IDs for session and events (no external dependency).
class UuidService {
  UuidService._internal();

  static final UuidService instance = UuidService._internal();

  final Random _rnd = Random();

  String generateSessionId() {
    return _randomHex(16);
  }

  String _randomHex(int length) {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < length; i++) {
      final v = _rnd.nextInt(16);
      sb.write(v.toRadixString(16));
    }
    return sb.toString();
  }
}
