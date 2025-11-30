import 'stream_representation.dart';

class AdaptiveStreamSession {
  final StreamRepresentation currentRepresentation;
  final int downloadedBytes;
  final Duration position;

  AdaptiveStreamSession({
    required this.currentRepresentation,
    required this.downloadedBytes,
    required this.position,
  });
}
