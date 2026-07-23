class YohPalVideoSource {
  final String id;
  final String title;
  final String lowUrl;    // 360p
  final String mediumUrl; // 480p
  final String highUrl;   // 720p
  final String? hlsUrl;
  final Map<String, String> headers;

  const YohPalVideoSource({
    required this.id,
    required this.title,
    required this.lowUrl,
    required this.mediumUrl,
    required this.highUrl,
    this.hlsUrl,
    this.headers = const {},
  });

  String bestUrl({
    required bool isWifi,
    required bool lowDataMode,
    required bool hlsEnabled,
  }) {
    if (hlsEnabled && hlsUrl != null) return hlsUrl!;
    if (lowDataMode) return lowUrl;
    if (isWifi) return highUrl;
    return mediumUrl;
  }
}
