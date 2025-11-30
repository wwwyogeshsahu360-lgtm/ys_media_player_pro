import 'adaptive_stream_session.dart';
import 'stream_representation.dart';

abstract class StreamerEvent {}

class ManifestLoadedEvent extends StreamerEvent {}

class SessionOpenedEvent extends StreamerEvent {
  final AdaptiveStreamSession session;
  SessionOpenedEvent(this.session);
}

class SegmentDownloadedEvent extends StreamerEvent {
  final int bytes;
  SegmentDownloadedEvent(this.bytes);
}

class BandwidthUpdatedEvent extends StreamerEvent {
  final int bitrate;
  BandwidthUpdatedEvent(this.bitrate);
}

class RepresentationChangedEvent extends StreamerEvent {
  final StreamRepresentation representation;
  RepresentationChangedEvent(this.representation);
}

class StreamerErrorEvent extends StreamerEvent {
  final String message;
  StreamerErrorEvent(this.message);
}
