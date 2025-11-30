class StreamRepresentation {
  final String id;
  final String url;
  final int bandwidth;
  final int width;
  final int height;
  final String mimeType;
  final String codecs;

  StreamRepresentation({
    required this.id,
    required this.url,
    required this.bandwidth,
    required this.width,
    required this.height,
    required this.mimeType,
    required this.codecs,
  });
}
