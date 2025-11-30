// lib/features/downloads/utils/download_utils.dart
import 'dart:math';
import 'dart:typed_data';

/// Simple exponential backoff with jitter in milliseconds.
int computeBackoffMs(int attempt, {int baseMs = 1000, int maxMs = 60000}) {
  final exp = pow(2, attempt.clamp(0, 10)).toInt();
  final raw = baseMs * exp;
  final jitter = Random().nextInt(baseMs);
  return (raw + jitter).clamp(baseMs, maxMs);
}

/// Extremely simple XOR "encryption". This is only a placeholder and
/// must be replaced with a real crypto solution if true security is needed.
/// For now we only expose it so the pipeline is ready.
Uint8List xorBytes(Uint8List input, int key) {
  final out = Uint8List(input.length);
  for (var i = 0; i < input.length; i++) {
    out[i] = input[i] ^ key;
  }
  return out;
}
