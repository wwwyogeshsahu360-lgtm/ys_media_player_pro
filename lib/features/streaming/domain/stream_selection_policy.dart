import 'stream_representation.dart';

abstract class StreamSelectionPolicy {
  StreamRepresentation selectBestRepresentation(
      List<StreamRepresentation> videoTracks,
      int availableBandwidth,
      );
}

class DefaultStreamSelectionPolicy implements StreamSelectionPolicy {
  @override
  StreamRepresentation selectBestRepresentation(
      List<StreamRepresentation> tracks, int bw) {
    tracks.sort((a, b) => a.bandwidth.compareTo(b.bandwidth));
    return tracks.lastWhere(
          (t) => t.bandwidth <= bw,
      orElse: () => tracks.first,
    );
  }
}
