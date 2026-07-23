class YohPalNativeVideoSource {
  final String id;
  final String url;
  final Map<String, String> headers;

  const YohPalNativeVideoSource({
    required this.id,
    required this.url,
    this.headers = const {},
  });
}
