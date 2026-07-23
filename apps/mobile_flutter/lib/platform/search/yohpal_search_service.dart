class YohPalSearchResult {
  final String id;
  final String type; // 'creator' | 'job' | 'product' | 'video' | 'stream'
  final String title;
  final String subtitle;
  final String route; // deep link — e.g. yohpal://live/creator/123

  const YohPalSearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

abstract class YohPalSearchService {
  Future<List<YohPalSearchResult>> search(String query);
}
