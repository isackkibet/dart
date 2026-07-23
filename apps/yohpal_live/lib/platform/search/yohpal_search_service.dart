class YohPalSearchResult {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String route;
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
