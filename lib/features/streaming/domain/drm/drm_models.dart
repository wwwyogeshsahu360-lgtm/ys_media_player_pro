class DrmSignal {
  final String keyId;
  final String scheme; // e.g. "widevine", "playready"
  final String licenseUrl;

  DrmSignal({
    required this.keyId,
    required this.scheme,
    required this.licenseUrl,
  });
}

enum DrmScheme {
  widevine,
  playready,
  fairplay,
  unknown,
}
